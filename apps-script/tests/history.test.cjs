const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
function backend() {
  const tables = {
    Users: [{memberCode:'GV1', role:'GV', fullName:'Teacher', email:'teacher@example.test'},
      {memberCode:'SV1', rollNumber:'SE1', fullName:'Student One', email:'one@example.test'},
      {memberCode:'SV2', rollNumber:'SE2', fullName:'Student Two', email:'two@example.test'}],
    Class_Section: [{classCode:'C1', teacherMemberCode:'GV1', subjectName:'Course', room:303},
      {classCode:'C2', teacherMemberCode:'GV1', subjectName:'Empty Course'},
      {classCode:'OTHER',teacherMemberCode:'GV2'}],
    Enrollment: [{classCode:'C1',rollNumber:'SE1'},{classCode:'C1',rollNumber:'SE2'},
      {classCode:'C1',rollNumber:'SE1'},{classCode:'C2',rollNumber:'SE2'}],
    Attendance_Session: [{sessionId:'S1',classCode:'C1',sessionDate:'2026-09-19',slotCode:'A1',sessionStatus:'closed',qrSecret:'secret'},
      {sessionId:'S2',classCode:'C1',sessionDate:'2026-09-20',slotCode:'A1',sessionStatus:'open',qrSecret:'secret2'}],
    Attendance_Record: [{recordId:'R1',sessionId:'S1',rollNumber:'SE1',status:'Present',checkinTime:'2026-09-19T00:30:00Z'}],
    Slot:[{slotCode:'A1',startTime:'07:00',endTime:'09:00'}],
  };
  const cache = new Map([['auth:teacher','GV1'],['auth:student','SV1']]);
  let writes=0, releases=0, uuid=0, zipParts;
  const context=vm.createContext({
    SheetDB:{
      getRowsAsObjects:name=>tables[name].map(r=>({...r})),
      ensureColumns:()=>{},
      updateRow:(name,field,id,update)=>{const r=tables[name].find(r=>r[field]===id);if(!r)return false;Object.assign(r,update);writes++;return true;},
      insertRow:(name,row)=>{tables[name].push({...row});writes++;return row;},
    },
    CacheService:{getScriptCache:()=>({get:k=>cache.get(k),put:(k,v)=>cache.set(k,v)})},
    UrlFetchApp:{fetch:()=>({getContentText:()=>JSON.stringify({email:'teacher@example.test'})})},
    LockService:{getScriptLock:()=>({waitLock:()=>{},releaseLock:()=>{releases++;}})},
    Utilities:{getUuid:()=>`uuid-${++uuid}`,newBlob:(body,type,name)=>({body,type,name}),
      zip:parts=>{zipParts=parts;return {getBytes:()=>[80,75]};},base64Encode:bytes=>Buffer.from(bytes).toString('base64')},
    ContentService:{MimeType:{JSON:'application/json'},createTextOutput:body=>({setMimeType:()=>JSON.parse(body)})},
  });
  for(const name of ['Response','AuthService','TeacherService','StudentService','SyncService','HistoryExcel','AttendanceHistoryService','Router','Code']) {
    vm.runInContext(fs.readFileSync(path.join(__dirname,'..',name+'.gs'),'utf8'),context);
  }
  function call(action,params={}) {return context.doPost({postData:{contents:JSON.stringify({action,sessionToken:'teacher',...params})}});}
  return {tables,call,context,get writes(){return writes;},get releases(){return releases;},get zipParts(){return zipParts;}};
}

test('real teacher classes, deduplicated enrollment and closed-only statistics',()=>{
  const b=backend();const r=b.call('getHistoryClasses');
  assert.equal(r.success,true);assert.equal(r.data.length,2);
  const c=r.data[0];assert.equal(c.room,'303');assert.equal(c.studentCount,2);
  assert.equal(c.totalSessions,2);assert.equal(c.completedSessions,1);
  assert.equal(c.attendanceRate,.5);assert.equal(c.lateRate,0);assert.equal(c.atRiskCount,1);
  assert.equal(c.latestSession.sessionId,'S2');assert.equal(c.latestSession.qrSecret,undefined);
});
test('empty sessions show enrolled students as unchecked, not fabricated absences',()=>{
  const r=backend().call('getHistoryDetail',{classCode:'C2'});
  assert.equal(r.success,true);assert.equal(r.data.selectedSession,null);assert.equal(r.data.students.length,1);
  assert.equal(r.data.students[0].status,'Unchecked');assert.equal(r.data.students[0].totalSessions,0);
});
test('missing record in open session is unchecked; closed session is absent',()=>{
  const b=backend();const open=b.call('getHistoryDetail',{classCode:'C1'}).data;
  assert.deepEqual(open.students.map(s=>s.status),['Unchecked','Unchecked']);
  const closed=b.call('getHistoryDetail',{classCode:'C1',sessionId:'S1'}).data;
  assert.deepEqual(closed.students.map(s=>s.status),['Present','Absent']);
  assert.equal(closed.students[1].absenceCount,1);
});
test('all history endpoints enforce authenticated teacher and class ownership',()=>{
  const b=backend();
  assert.equal(b.call('getHistoryClasses',{sessionToken:'fake',teacherMemberCode:'GV1'}).error.code,'UNAUTHORIZED');
  assert.equal(b.call('getHistoryClasses',{sessionToken:'student'}).error.code,'FORBIDDEN');
  for(const action of ['getHistoryDetail','getAttendanceMatrix','exportAttendanceHistory','startHistorySession']){
    assert.equal(b.call(action,{classCode:'OTHER'}).error.code,'FORBIDDEN');
  }
  assert.equal(b.call('getHistoryDetail',{classCode:'C1',sessionId:'wrong'}).error.code,'SESSION_NOT_FOUND');
});
test('save persists notes and status, updates statistics and detects concurrent changes',()=>{
  const b=backend();const initial=b.call('getHistoryDetail',{classCode:'C1',sessionId:'S1'}).data;
  const change={rollNumber:'SE2',status:'ManualByGV',note:'Teacher checked',revision:initial.students[1].revision};
  const r=b.call('saveAttendanceChanges',{classCode:'C1',sessionId:'S1',changes:[change]});
  assert.equal(r.success,true);assert.equal(r.data.classInfo.attendanceRate,1);
  assert.equal(r.data.students[1].note,'Teacher checked');assert.equal(r.data.students[1].checkinTime,'');
  assert.equal(b.tables.Attendance_Record.at(-1).syncedToFap,false);
  assert.equal(b.call('saveAttendanceChanges',{classCode:'C1',sessionId:'S1',changes:[change]}).error.code,'CONFLICT');
  assert.equal(b.writes,1);assert.equal(b.releases,2);
});
test('validates entire change batch before any writes',()=>{
  const b=backend();const params={classCode:'C1',sessionId:'S2',changes:[
    {rollNumber:'SE1',status:'Late',note:'',revision:''},{rollNumber:'unknown',status:'Late',note:'',revision:''}]};
  assert.equal(b.call('saveAttendanceChanges',params).error.code,'VALIDATION_ERROR');assert.equal(b.writes,0);
  params.changes=[{rollNumber:'SE1',status:'invented',note:'',revision:''}];
  assert.equal(b.call('saveAttendanceChanges',params).error.code,'VALIDATION_ERROR');assert.equal(b.writes,0);
});
test('matrix uses actual session identities and student status',()=>{
  const r=backend().call('getAttendanceMatrix',{classCode:'C1'});
  assert.deepEqual(r.data.sessions.map(s=>s.sessionId),['S2','S1']);
  assert.deepEqual(r.data.students[0].statuses,['Unchecked','Present']);
});
test('xlsx export escapes user data and writes inline text rather than formulas',()=>{
  const b=backend();b.tables.Users[1].fullName='=1+1 & <text>';
  const r=b.call('exportAttendanceHistory',{classCode:'C1',sessionId:'S1'});
  assert.equal(r.success,true);assert.equal(r.data.filename,'Attendance_C1.xlsx');
  assert.equal(b.zipParts.length,5);
  const xml=b.zipParts.find(p=>p.name==='xl/worksheets/sheet1.xml').body;
  assert.match(xml,/=1\+1 &amp; &lt;text&gt;/);assert.ok(!xml.includes('<f>'));
  assert.ok(b.zipParts.some(p=>p.name==='[Content_Types].xml'));
});
test('login stores server session used by history endpoints',()=>{
  const b=backend();const login=b.call('login',{idToken:'verified-by-stub'});
  assert.equal(login.success,true);
  assert.equal(b.call('getHistoryClasses',{sessionToken:login.data.token}).data.length,2);
});
test('opening a session requires valid slot and rejects duplicate open sessions',()=>{
  const b=backend();
  assert.equal(b.call('startHistorySession',{classCode:'C1',slotCode:'A1',teacherIp:'203.0.113.1'}).error.code,'SESSION_ALREADY_OPEN');
  assert.equal(b.call('startHistorySession',{classCode:'C2',slotCode:'missing',teacherIp:'203.0.113.1'}).error.code,'VALIDATION_ERROR');
  const r=b.call('startHistorySession',{classCode:'C2',slotCode:'A1',teacherIp:'203.0.113.1'});
  assert.equal(r.success,true);assert.equal(r.data.session.classCode,'C2');
});
