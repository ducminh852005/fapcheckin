// File: FirestoreStore.gs
//
// Cloud Firestore implementation of the SheetDB contract (see SheetDB.gs).
// It keeps the sheet-era row objects and the sheet names used by the services,
// and maps them onto the collections designed in docs/db-erd.mermaid.
//
// Auth: the Web App runs as the script owner. ScriptApp.getOAuthToken() needs
// the `datastore` scope in appsscript.json and the owner needs the "Cloud
// Datastore User" IAM role on the project. X-Goog-User-Project makes the call
// count against the Firebase project instead of Apps Script's hidden project.

var FirestoreStore = (function() {
  var DEFAULT_PROJECT_ID = 'fapcheckin-30e86';
  var PAGE_SIZE = 300;
  var RETRY_STATUS = [429, 500, 502, 503, 504];
  var MAX_ATTEMPTS = 3;
  var MEMO_SHEETS = ['Users', 'Slot', 'Class_Section'];
  var PERIOD_LABEL = { Morning: 'Morning (A)', Afternoon: 'Afternoon (P)' };

  // sheet name (as used by the services) -> collection + document id fields
  var SCHEMA = {
    Users: { collection: 'users', key: ['memberCode'] },
    Class_Section: { collection: 'classSections', key: ['classCode'], subject: true },
    Slot: { collection: 'slots', key: ['slotCode'], readOnly: true, timeSlots: true },
    Enrollment: { collection: 'enrollments', key: ['classCode', 'rollNumber'] },
    Class_Schedule: { collection: 'classSchedules', key: ['scheduleId'] },
    Attendance_Session: { collection: 'attendanceSessions', key: ['sessionId'] },
    Attendance_Record: { collection: 'attendanceRecords', key: ['sessionId', 'rollNumber'] }
  };

  var memo = {};

  // ------------------------------------------------------------- utilities
  function projectId() {
    var configured = null;
    try {
      if (typeof PropertiesService !== 'undefined') {
        configured = PropertiesService.getScriptProperties().getProperty('FIREBASE_PROJECT_ID');
      }
    } catch (e) {}
    return configured || DEFAULT_PROJECT_ID;
  }

  function databaseName() {
    return 'projects/' + projectId() + '/databases/(default)';
  }

  function baseUrl() {
    return 'https://firestore.googleapis.com/v1/' + databaseName() + '/documents';
  }

  function schemaFor(sheetName) {
    var schema = SCHEMA[sheetName];
    if (!schema) throwError('SHEET_NOT_FOUND', 'Không tìm thấy bảng: ' + sheetName);
    return schema;
  }

  function docIdOf(schema, rowObj) {
    var parts = schema.key.map(function(field) {
      var value = rowObj[field];
      if (value == null || String(value).trim() === '') {
        throwError('VALIDATION_ERROR', 'Thiếu khóa "' + field + '" khi ghi ' + schema.collection + '.');
      }
      return String(value).trim().replace(/\//g, '_');
    });
    return parts.join('_');
  }

  function textValue(field, value) {
    if (value == null) return '';
    if (Object.prototype.toString.call(value) === '[object Date]') return value;
    var isText = SheetsStore.TEXT_FIELDS.indexOf(field) !== -1;
    return isText && typeof value !== 'string' ? String(value).trim() : value;
  }

  // ---------------------------------------------------------- value coding
  function encodeValue(value) {
    if (value == null) return { nullValue: null };
    if (Object.prototype.toString.call(value) === '[object Date]') {
      return { timestampValue: value.toISOString() };
    }
    if (Array.isArray(value)) {
      return { arrayValue: { values: value.map(encodeValue) } };
    }
    switch (typeof value) {
      case 'boolean': return { booleanValue: value };
      case 'number':
        return isFinite(value) && Math.floor(value) === value
          ? { integerValue: String(value) }
          : { doubleValue: value };
      case 'object': return { mapValue: { fields: encodeFields(value) } };
      default: return { stringValue: String(value) };
    }
  }

  function encodeFields(obj, skip) {
    var fields = {};
    Object.keys(obj).forEach(function(key) {
      if (obj[key] === undefined || (skip && skip.indexOf(key) !== -1)) return;
      fields[key] = encodeValue(textValue(key, obj[key]));
    });
    return fields;
  }

  function decodeValue(value) {
    if (!value || 'nullValue' in value) return '';
    if ('stringValue' in value) return value.stringValue;
    if ('integerValue' in value) return Number(value.integerValue);
    if ('doubleValue' in value) return Number(value.doubleValue);
    if ('booleanValue' in value) return value.booleanValue;
    if ('timestampValue' in value) return value.timestampValue;
    if ('arrayValue' in value) return (value.arrayValue.values || []).map(decodeValue);
    if ('mapValue' in value) return decodeFields(value.mapValue.fields || {});
    return '';
  }

  function decodeFields(fields) {
    var obj = {};
    Object.keys(fields || {}).forEach(function(key) { obj[key] = decodeValue(fields[key]); });
    return obj;
  }

  function idFromName(name) {
    return String(name).split('/').pop();
  }

  // ------------------------------------------------------------- transport
  function request(method, url, payload, allowStatus) {
    var lastError;
    for (var attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
      var response = UrlFetchApp.fetch(url, {
        method: method,
        contentType: 'application/json',
        headers: {
          Authorization: 'Bearer ' + ScriptApp.getOAuthToken(),
          'X-Goog-User-Project': projectId()
        },
        payload: payload === undefined ? undefined : JSON.stringify(payload),
        muteHttpExceptions: true
      });
      var status = response.getResponseCode();
      var text = response.getContentText();
      var body = null;
      try { body = text ? JSON.parse(text) : null; } catch (e) { body = null; }
      if (status >= 200 && status < 300) return { status: status, body: body };
      if (allowStatus && allowStatus.indexOf(status) !== -1) return { status: status, body: body };
      var message = (body && body.error && body.error.message) || text || ('HTTP ' + status);
      lastError = fail(status, message);
      if (RETRY_STATUS.indexOf(status) === -1 || attempt === MAX_ATTEMPTS) break;
      if (typeof Utilities !== 'undefined' && Utilities.sleep) Utilities.sleep(300 * attempt);
    }
    throw lastError;
  }

  function fail(status, message) {
    var code = 'DB_UNAVAILABLE';
    if (status === 401 || status === 403) code = 'DB_PERMISSION';
    else if (status === 409) code = 'DB_CONFLICT';
    else if (status === 400 || status === 404) code = 'DB_ERROR';
    var error = new Error('Firestore ' + status + ': ' + message);
    error.code = code;
    return error;
  }

  // ------------------------------------------------------------------ reads
  function listAll(collection) {
    var docs = [];
    var pageToken = '';
    do {
      var url = baseUrl() + '/' + collection + '?pageSize=' + PAGE_SIZE +
        (pageToken ? '&pageToken=' + encodeURIComponent(pageToken) : '');
      var body = request('GET', url, undefined, [404]).body || {};
      (body.documents || []).forEach(function(doc) { docs.push(doc); });
      pageToken = body.nextPageToken || '';
    } while (pageToken);
    return docs;
  }

  function runQuery(collection, hint) {
    var filters = Object.keys(hint).map(function(field) {
      return {
        fieldFilter: { field: { fieldPath: field }, op: 'EQUAL', value: encodeValue(hint[field]) }
      };
    });
    var structuredQuery = { from: [{ collectionId: collection }] };
    if (filters.length === 1) structuredQuery.where = filters[0];
    else if (filters.length > 1) structuredQuery.where = { compositeFilter: { op: 'AND', filters: filters } };
    var body = request('POST', baseUrl() + ':runQuery', { structuredQuery: structuredQuery }).body || [];
    return body.filter(function(item) { return item && item.document; })
      .map(function(item) { return item.document; });
  }

  function isPlainHint(hint) {
    if (!hint || typeof hint !== 'object') return false;
    var keys = Object.keys(hint);
    return keys.length > 0 && keys.every(function(key) {
      var v = hint[key];
      return typeof v === 'string' || typeof v === 'number' || typeof v === 'boolean';
    });
  }

  // Sheet order: rows imported from the sheet keep `_row`; later inserts follow
  // by Firestore createTime. Several services rely on "latest row wins".
  function sortDocs(docs) {
    return docs.map(function(doc, index) {
      var row = doc.fields && doc.fields._row ? decodeValue(doc.fields._row) : Infinity;
      return { doc: doc, row: typeof row === 'number' ? row : Infinity, index: index };
    }).sort(function(a, b) {
      if (a.row !== b.row) return a.row < b.row ? -1 : 1;
      var ta = a.doc.createTime || '', tb = b.doc.createTime || '';
      if (ta !== tb) return ta < tb ? -1 : 1;
      return String(a.doc.name).localeCompare(String(b.doc.name));
    }).map(function(item) { return item.doc; });
  }

  function toRow(doc) {
    var row = decodeFields(doc.fields || {});
    Object.keys(row).forEach(function(key) { if (key.charAt(0) === '_') delete row[key]; });
    return row;
  }

  function readLookup(collection) {
    var key = '_lookup:' + collection;
    if (memo[key]) return memo[key];
    var lookup = {};
    listAll(collection).forEach(function(doc) {
      lookup[idFromName(doc.name)] = decodeFields(doc.fields || {});
    });
    memo[key] = lookup;
    return lookup;
  }

  function readSubjects() { return readLookup('subjects'); }
  function readTimeSlots() { return readLookup('timeSlots'); }

  function clone(rows) {
    return rows.map(function(row) { return Object.assign({}, row); });
  }

  function getRowsAsObjects(sheetName, hint) {
    var schema = schemaFor(sheetName);
    var memoizable = MEMO_SHEETS.indexOf(sheetName) !== -1 && !isPlainHint(hint);
    if (memoizable && memo[sheetName]) return clone(memo[sheetName]);

    var docs = isPlainHint(hint) && !schema.timeSlots
      ? runQuery(schema.collection, hint)
      : listAll(schema.collection);
    var rows = sortDocs(docs).map(toRow);

    if (schema.subject) {
      var subjects = readSubjects();
      rows = rows.map(function(row) {
        var subject = subjects[row.subjectCode] || {};
        if (row.subjectName == null || row.subjectName === '') row.subjectName = subject.subjectName || '';
        if (row.credits == null || row.credits === '') row.credits = subject.credits == null ? '' : subject.credits;
        return row;
      });
    }
    if (schema.timeSlots) {
      var timeSlots = readTimeSlots();
      rows = rows.map(function(row) {
        var block = timeSlots[row.timeSlotId] || {};
        row.period = PERIOD_LABEL[block.period] || block.period || '';
        row.startTime = block.startTime || '';
        row.endTime = block.endTime || '';
        row.daySlotNo = block.daySlotNo == null ? '' : block.daySlotNo;
        return row;
      });
    }
    if (memoizable) memo[sheetName] = clone(rows);
    return rows;
  }

  // ----------------------------------------------------------------- writes
  function forget(sheetName) {
    delete memo[sheetName];
    if (sheetName === 'Class_Section') delete memo['_lookup:subjects'];
  }

  function splitClassSection(rowObj) {
    var classRow = Object.assign({}, rowObj);
    var subject = {};
    if (classRow.subjectName !== undefined) subject.subjectName = classRow.subjectName;
    if (classRow.credits !== undefined && classRow.credits !== '') subject.credits = Number(classRow.credits);
    delete classRow.subjectName;
    delete classRow.credits;
    if (classRow.studentCount !== undefined && classRow.studentCount !== '') {
      classRow.studentCount = Number(classRow.studentCount) || 0;
    }
    return { classRow: classRow, subject: subject };
  }

  function upsertSubject(subjectCode, subject, onlyIfMissing) {
    if (!subjectCode || Object.keys(subject).length === 0) return;
    var url = baseUrl() + '/subjects/' + encodeURIComponent(subjectCode);
    if (onlyIfMissing) {
      // Creating a document that already exists is the expected no-op here.
      request('POST', baseUrl() + '/subjects?documentId=' + encodeURIComponent(subjectCode), {
        fields: encodeFields(Object.assign({ subjectCode: subjectCode }, subject))
      }, [409]);
      return;
    }
    var mask = Object.keys(subject).map(function(f) {
      return 'updateMask.fieldPaths=' + encodeURIComponent(f);
    }).join('&');
    request('PATCH', url + '?' + mask, { fields: encodeFields(subject) });
  }

  function insertRow(sheetName, rowObj) {
    var schema = schemaFor(sheetName);
    if (schema.readOnly) return rowObj; // Slot times are fixed by the A/P schedule rule.

    var data = rowObj;
    var subject = null;
    if (schema.subject) {
      var split = splitClassSection(rowObj);
      data = split.classRow;
      if (!data.subjectCode) data.subjectCode = SheetsStore.subjectCodeFromClassCode(data.classCode);
      subject = split.subject;
    }
    var id = docIdOf(schema, data);
    request('POST', baseUrl() + '/' + schema.collection + '?documentId=' + encodeURIComponent(id), {
      fields: encodeFields(data)
    });
    if (subject) upsertSubject(data.subjectCode, subject, true);
    forget(sheetName);
    return rowObj;
  }

  function updateRow(sheetName, idField, idValue, updateObj) {
    var schema = schemaFor(sheetName);
    if (schema.readOnly) return true;

    var data = updateObj;
    var subject = null;
    if (schema.subject) {
      var split = splitClassSection(updateObj);
      data = split.classRow;
      subject = split.subject;
    }

    var docName;
    if (schema.key.length === 1 && schema.key[0] === idField) {
      docName = databaseName() + '/documents/' + schema.collection + '/' +
        encodeURIComponent(String(idValue).trim().replace(/\//g, '_'));
    } else {
      var found = runQuery(schema.collection, (function() {
        var hint = {}; hint[idField] = idValue; return hint;
      })());
      if (!found.length) return false;
      docName = found[0].name;
    }

    var fieldNames = Object.keys(data).filter(function(f) { return data[f] !== undefined; });
    if (fieldNames.length) {
      var mask = fieldNames.map(function(f) {
        return 'updateMask.fieldPaths=' + encodeURIComponent(f);
      }).join('&');
      var url = 'https://firestore.googleapis.com/v1/' + docName + '?' + mask + '&currentDocument.exists=true';
      var response = request('PATCH', url, { fields: encodeFields(data) }, [404]);
      if (response.status === 404) return false;
    } else if (!documentExists(docName)) {
      return false;
    }
    if (subject && Object.keys(subject).length) {
      var classCode = String(idField === 'classCode' ? idValue : data.classCode || '').trim();
      var subjectCode = data.subjectCode || SheetsStore.subjectCodeFromClassCode(classCode);
      upsertSubject(subjectCode, subject, false);
    }
    forget(sheetName);
    return true;
  }

  function documentExists(docName) {
    return request('GET', 'https://firestore.googleapis.com/v1/' + docName, undefined, [404]).status !== 404;
  }

  // Firestore is schemaless: there are no tabs or header columns to maintain.
  function ensureSheet() {}
  function ensureColumns() {}

  // Direct helpers used by Migrate.gs (upsert = full replace of the document).
  function batchUpsert(collection, items) {
    var errors = [];
    for (var start = 0; start < items.length; start += 200) {
      var chunk = items.slice(start, start + 200);
      var writes = chunk.map(function(item) {
        return {
          update: {
            name: databaseName() + '/documents/' + collection + '/' + encodeURIComponent(item.id),
            fields: encodeFields(item.fields)
          }
        };
      });
      var body = request('POST', baseUrl() + ':batchWrite', { writes: writes }).body || {};
      (body.status || []).forEach(function(status, index) {
        if (status && status.code) {
          errors.push(collection + '/' + chunk[index].id + ': ' + (status.message || status.code));
        }
      });
    }
    forgetAll();
    return errors;
  }

  function listIds(collection) {
    return listAll(collection).map(function(doc) { return idFromName(doc.name); });
  }

  function forgetAll() { memo = {}; }

  function ping() {
    request('GET', baseUrl() + '/subjects?pageSize=1', undefined, [404]);
    return { projectId: projectId(), ok: true };
  }

  return {
    ensureSheet: ensureSheet,
    ensureColumns: ensureColumns,
    getRowsAsObjects: getRowsAsObjects,
    insertRow: insertRow,
    updateRow: updateRow,
    // internals shared with Migrate.gs and the tests
    batchUpsert: batchUpsert,
    listIds: listIds,
    ping: ping,
    projectId: projectId,
    docIdOf: function(sheetName, rowObj) { return docIdOf(schemaFor(sheetName), rowObj); },
    SCHEMA: SCHEMA,
    encodeValue: encodeValue,
    decodeValue: decodeValue
  };
})();
