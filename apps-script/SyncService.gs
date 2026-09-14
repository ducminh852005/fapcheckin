// File: SyncService.gs

var SyncService = (function() {
  
  function syncToFap() {
    var records = SheetDB.getRowsAsObjects('Attendance_Record');
    var unsynced = records.filter(function(r) { return r.syncedToFap === false || r.syncedToFap === 'FALSE'; });
    
    if (unsynced.length === 0) return 0;
    
    // TODO: Thực hiện gọi API thật tới FAP endpoint
    // UrlFetchApp.fetch(fapUrl, { method: 'post', payload: JSON.stringify(unsynced) });
    
    // Cập nhật trạng thái
    for (var i = 0; i < unsynced.length; i++) {
      SheetDB.updateRow('Attendance_Record', 'recordId', unsynced[i].recordId, { syncedToFap: true });
    }
    
    return unsynced.length;
  }
  
  return {
    syncToFap: syncToFap
  };
})();
