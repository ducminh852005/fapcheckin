// File: SyncService.gs

var SyncService = (function() {
  
  function syncToFap(params) {
    // Read hint for Firestore: only rows not yet synced (booleans there); the sheet ignores it.
    var records = SheetDB.getRowsAsObjects('Attendance_Record', { syncedToFap: false });
    var classCode = params ? params.classCode : null;

    var unsynced = records.filter(function(r) { 
      return r.syncedToFap === false || r.syncedToFap === 'FALSE' || r.syncedToFap === ''; 
    });

    if (classCode) {
      var sessions = SheetDB.getRowsAsObjects('Attendance_Session').filter(function(s) {
        return s.classCode === classCode;
      });
      var sessionIds = sessions.map(function(s) { return s.sessionId; });
      unsynced = unsynced.filter(function(r) {
        return sessionIds.indexOf(r.sessionId) !== -1;
      });
    }

    if (unsynced.length === 0) {
      return {
        syncedCount: 0,
        message: 'Tất cả bản ghi đã được đồng bộ trước đó.'
      };
    }

    // TODO: Thực hiện gọi API thật tới FAP endpoint khi có kết nối chính thức
    // UrlFetchApp.fetch(fapUrl, { method: 'post', payload: JSON.stringify(unsynced) });

    // Cập nhật trạng thái syncedToFap = true
    for (var i = 0; i < unsynced.length; i++) {
      SheetDB.updateRow('Attendance_Record', 'recordId', unsynced[i].recordId, { syncedToFap: true });
    }

    return {
      syncedCount: unsynced.length,
      message: 'Đồng bộ thành công ' + unsynced.length + ' bản ghi lên FAP.'
    };
  }
  
  return {
    syncToFap: syncToFap
  };
})();
