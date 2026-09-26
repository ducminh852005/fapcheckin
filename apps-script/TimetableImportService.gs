// Imports a teacher's FAP timetable screenshot using temporary Google Drive OCR.
var TimetableImportService = (function() {
  // The image is sent as base64 inside a JSON request, so accepting hundreds
  // of megabytes here would exceed the web-app request/runtime limits long
  // before OCR starts. A timetable screenshot is normally well below 1 MB.
  var MAX_FILE_BYTES = 10 * 1024 * 1024;
  var CACHE_SECONDS = 600;
  // A newly converted Google Doc is not always readable immediately. Retry
  // long enough for Drive OCR to finish instead of reporting a false
  // authorization error while the document is still being prepared.
  var OCR_READ_DELAYS_MS = [0, 500, 1000, 2000, 3000, 5000];
  var ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/bmp'];

  function text(value) {
    return value == null ? '' : String(value).trim();
  }

  function normalizedCode(value) {
    return text(value).toUpperCase().replace(/[^A-Z0-9]/g, '');
  }

  function parseText(ocrText) {
    var source = text(ocrText)
      .toUpperCase()
      .replace(/[–—−_]/g, '-')
      .replace(/\r/g, '\n')
      // Drive OCR occasionally inserts spaces inside identifiers.
      .replace(/\b([A-Z]{2,4})\s+(\d{3,5})\b/g, '$1$2')
      .replace(/\b([A-Z]{2,5})\s+(\d{3})\b/g, '$1$2');
    var entries = [];
    var seen = {};
    // Match the stable part first. Requiring "at NVH" caused clear images to
    // be rejected whenever OCR reordered table columns or dropped that label.
    var pattern = /\b([A-Z]{2,4}\d{3,5})(?:\s*-\s*|\s+)([A-Z]{2,5}\d{3})\b/g;
    var match;
    while ((match = pattern.exec(source)) !== null) {
      var classCode = match[1];
      var subjectCode = match[2];
      var key = classCode + '|' + subjectCode;
      if (seen[key]) continue;
      seen[key] = true;

      // Room is optional and is normally close to the code. Limit the lookup
      // window so a room from the next timetable cell is never attached.
      var afterCode = source.slice(pattern.lastIndex, pattern.lastIndex + 60);
      var roomMatch = /^\s+AT\s+[A-Z]{2,8}(?:\s*-)?\s*(\d{3,4}|[A-Z]\d{2,4})\b/.exec(afterCode);
      entries.push({
        key: key,
        classCode: classCode,
        subjectCode: subjectCode,
        room: roomMatch ? roomMatch[1] : ''
      });
    }

    var dates = [];
    var dateSeen = {};
    var datePattern = /\b(\d{1,2})[\/-](\d{1,2})(?:[\/-](\d{2,4}))?\b/g;
    while ((match = datePattern.exec(source)) !== null) {
      var day = ('0' + match[1]).slice(-2);
      var month = ('0' + match[2]).slice(-2);
      var value = day + '/' + month + (match[3] ? '/' + match[3] : '');
      if (!dateSeen[value]) {
        dateSeen[value] = true;
        dates.push(value);
      }
    }
    return {entries: entries, detectedDates: dates};
  }

  function errorText(error) {
    if (!error) return '';
    return text(error.message || error.toString());
  }

  function readOcrDocument(documentId) {
    var lastError = null;
    for (var attempt = 0; attempt < OCR_READ_DELAYS_MS.length; attempt++) {
      if (OCR_READ_DELAYS_MS[attempt]) Utilities.sleep(OCR_READ_DELAYS_MS[attempt]);
      try {
        var extracted = text(DocumentApp.openById(documentId).getBody().getText());
        if (extracted) return extracted;
      } catch (error) {
        lastError = error;
      }
    }
    if (lastError) throw lastError;
    return '';
  }

  function throwOcrError(error, stage) {
    var message = errorText(error);
    console.error('Timetable OCR failed at ' + stage + ': ' + message);

    // Only the Drive conversion call can reliably prove that the deployment
    // lacks OCR authorization. Once it returns a document id, transient
    // permission/not-found errors usually mean that conversion is not ready.
    if (stage === 'create' && /authoriz|permission|access denied|insufficient|not enabled|has not been used|is not defined|is not a function/i.test(message)) {
      throwError(
        'OCR_NOT_CONFIGURED',
        'Dịch vụ quét thời khóa biểu chưa được cấp quyền Google Drive/Docs. Quản trị viên cần cấp lại quyền OCR rồi thử lại.'
      );
    }
    if (/quota|rate.?limit|too many|service invoked too many/i.test(message)) {
      throwError(
        'OCR_BUSY',
        'Dịch vụ nhận dạng đang quá tải hoặc đã đạt giới hạn tạm thời. Vui lòng thử lại sau ít phút.'
      );
    }
    if (stage === 'read') {
      throwError(
        'OCR_PROCESSING_TIMEOUT',
        'Google OCR đã nhận ảnh nhưng chưa hoàn tất xử lý. Vui lòng thử lại ảnh sau vài giây.'
      );
    }
    throwError(
      'OCR_UNAVAILABLE',
      'Google OCR chưa xử lý được ảnh lúc này. Vui lòng thử lại; nếu lỗi tiếp diễn, liên hệ quản trị viên.'
    );
  }

  function subjectCodeOf(classRow) {
    var direct = normalizedCode(classRow.subjectCode);
    if (direct) return direct;
    var classCodeParts = text(classRow.classCode).toUpperCase().split(/[^A-Z0-9]+/);
    for (var i = 0; i < classCodeParts.length; i++) {
      if (/^[A-Z]{2,5}\d{3}$/.test(classCodeParts[i])) return classCodeParts[i];
    }
    var fromName = /^([A-Z]{2,5}\d{3})\b/.exec(text(classRow.subjectName).toUpperCase());
    return fromName ? normalizedCode(fromName[1]) : '';
  }

  function matchEntries(parsed, teacher) {
    var classes = SheetDB.getRowsAsObjects('Class_Section');
    return parsed.entries.map(function(entry) {
      var matches = classes.filter(function(classRow) {
        var rowClass = normalizedCode(classRow.classCode);
        var wantedClass = normalizedCode(entry.classCode);
        var wantedSubject = normalizedCode(entry.subjectCode);
        var classMatches = rowClass === wantedClass ||
          rowClass === wantedClass + wantedSubject ||
          rowClass === wantedSubject + wantedClass;
        return classMatches && subjectCodeOf(classRow) === wantedSubject;
      });
      var result = {
        key: entry.key,
        classCode: entry.classCode,
        subjectCode: entry.subjectCode,
        room: entry.room,
        matchedClassCode: null,
        status: 'notFound',
        message: 'Không tìm thấy lớp tương ứng trong Class_Section.'
      };
      if (matches.length > 1) {
        result.status = 'ambiguous';
        result.message = 'Có nhiều lớp trùng mã; cần kiểm tra dữ liệu nhà trường.';
        return result;
      }
      if (matches.length === 0) return result;
      var matched = matches[0];
      result.matchedClassCode = text(matched.classCode);
      var owner = text(matched.teacherMemberCode);
      if (!owner) {
        result.status = 'available';
        result.message = 'Sẵn sàng thêm vào lớp.';
      } else if (owner === text(teacher.memberCode)) {
        result.status = 'alreadyAssigned';
        result.message = 'Giáo viên đã có trong lớp này.';
      } else {
        result.status = 'conflict';
        result.message = 'Lớp đã được phân công cho giáo viên khác.';
      }
      return result;
    });
  }

  function extractText(params) {
    var mimeType = text(params.mimeType).toLowerCase();
    if (ALLOWED_MIME_TYPES.indexOf(mimeType) === -1) {
      throwError('INVALID_IMAGE', 'Chỉ hỗ trợ ảnh JPG, PNG, GIF hoặc BMP.');
    }
    var encoded = text(params.imageBase64).replace(/^data:[^;]+;base64,/, '');
    if (!encoded) throwError('INVALID_IMAGE', 'Ảnh thời khóa biểu đang trống.');
    var bytes;
    try {
      bytes = Utilities.base64Decode(encoded);
    } catch (error) {
      throwError('INVALID_IMAGE', 'Dữ liệu ảnh không hợp lệ.');
    }
    if (bytes.length > MAX_FILE_BYTES) {
      throwError('IMAGE_TOO_LARGE', 'Ảnh vượt quá 10 MB. Vui lòng cắt gọn hoặc nén ảnh rồi thử lại.');
    }

    var blob = Utilities.newBlob(bytes, mimeType, text(params.fileName) || 'timetable');
    var documentId = '';
    var extractedText = '';
    var ocrError = null;
    var ocrStage = 'create';
    try {
      var resource = {
        name: 'fapcheckin-ocr-' + Utilities.getUuid(),
        mimeType: 'application/vnd.google-apps.document'
      };
      var document = Drive.Files.create(resource, blob, {
        ocrLanguage: 'en',
        fields: 'id'
      });
      documentId = document && document.id ? document.id : '';
      if (!documentId) throw new Error('Drive OCR did not return a document id.');
      ocrStage = 'read';
      extractedText = readOcrDocument(documentId);
    } catch (error) {
      ocrError = error;
    } finally {
      if (documentId) {
        try { DriveApp.getFileById(documentId).setTrashed(true); } catch (ignored) {}
      }
    }
    if (ocrError) throwOcrError(ocrError, ocrStage);
    if (!extractedText) {
      throwError(
        'OCR_EMPTY',
        'Google OCR không tìm thấy chữ trong ảnh. Hãy bảo đảm ảnh có đầy đủ bảng thời khóa biểu và thử lại.'
      );
    }
    return extractedText;
  }

  function scan(params) {
    var teacher = AuthService.requireTeacher(params);
    var parsed = parseText(extractText(params));
    var entries = matchEntries(parsed, teacher);
    if (entries.length === 0) {
      throwError(
        'NO_TIMETABLE_ENTRIES',
        'Không nhận ra cặp mã lớp–môn (ví dụ SE1917-PRN232). Hãy dùng ảnh thời khóa biểu dành cho giáo viên.'
      );
    }
    var allowedClassCodes = entries.filter(function(entry) {
      return entry.status === 'available';
    }).map(function(entry) { return entry.matchedClassCode; });
    var scanToken = Utilities.getUuid();
    CacheService.getScriptCache().put('timetable-scan:' + scanToken, JSON.stringify({
      teacherMemberCode: text(teacher.memberCode),
      classCodes: allowedClassCodes
    }), CACHE_SECONDS);
    return {
      scanToken: scanToken,
      entries: entries,
      detectedDates: parsed.detectedDates
    };
  }

  function importAssignments(params) {
    var teacher = AuthService.requireTeacher(params);
    var scanToken = text(params.scanToken);
    var cached = scanToken && CacheService.getScriptCache().get('timetable-scan:' + scanToken);
    if (!cached) throwError('SCAN_EXPIRED', 'Kết quả quét đã hết hạn. Vui lòng quét lại ảnh.');
    var proof = JSON.parse(cached);
    if (text(proof.teacherMemberCode) !== text(teacher.memberCode)) {
      throwError('FORBIDDEN', 'Kết quả quét không thuộc giáo viên đang đăng nhập.');
    }
    var requested = Array.isArray(params.classCodes) ? params.classCodes.map(text) : [];
    requested = requested.filter(function(code, index, all) {
      return code && all.indexOf(code) === index;
    });
    if (requested.length === 0) throwError('VALIDATION_ERROR', 'Chưa chọn lớp nào để thêm.');
    var allowed = proof.classCodes || [];
    if (requested.some(function(code) { return allowed.indexOf(code) === -1; })) {
      throwError('FORBIDDEN', 'Danh sách lớp không khớp với kết quả quét đã xác thực.');
    }

    var lock = LockService.getScriptLock();
    lock.waitLock(30000);
    try {
      var classes = SheetDB.getRowsAsObjects('Class_Section');
      var assigned = 0;
      var alreadyAssigned = 0;
      var rowsToAssign = [];
      // Validate the complete batch before writing so a late ownership change
      // cannot leave a partially imported timetable.
      requested.forEach(function(classCode) {
        var classRow = classes.filter(function(row) {
          return text(row.classCode) === classCode;
        })[0];
        if (!classRow) throwError('CLASS_NOT_FOUND', 'Lớp ' + classCode + ' không còn tồn tại.');
        var owner = text(classRow.teacherMemberCode);
        if (owner && owner !== text(teacher.memberCode)) {
          throwError('ASSIGNMENT_CONFLICT', 'Lớp ' + classCode + ' vừa được phân công cho giáo viên khác.');
        }
        if (owner === text(teacher.memberCode)) {
          alreadyAssigned++;
          return;
        }
        rowsToAssign.push(classCode);
      });
      rowsToAssign.forEach(function(classCode) {
        if (!SheetDB.updateRow('Class_Section', 'classCode', classCode, {
          teacherMemberCode: text(teacher.memberCode)
        })) {
          throwError('UPDATE_FAILED', 'Không thể cập nhật lớp ' + classCode + '.');
        }
        assigned++;
      });
      CacheService.getScriptCache().remove('timetable-scan:' + scanToken);
      return {
        assignedCount: assigned,
        alreadyAssignedCount: alreadyAssigned,
        classCodes: requested
      };
    } finally {
      lock.releaseLock();
    }
  }

  return {
    scan: scan,
    importAssignments: importAssignments,
    parseText: parseText,
    matchEntries: matchEntries
  };
})();
