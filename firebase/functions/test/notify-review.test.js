import { test } from 'node:test';
import assert from 'node:assert/strict';
import { pushToUser } from '../src/notify.js';
import { fakeDb, fakeMessaging, deps } from './fakes.js';
test('CR-01: payload invalid-argument preserves valid registration tokens', async () => {
 const db = fakeDb({'device_tokens/u/tokens/a': {token:'a'}});
 const result = await pushToUser(deps(db, fakeMessaging({'a':'messaging/invalid-argument'})), 'u', {title:'x',body:'y'});
 assert.equal(result.failed,1); assert.equal(result.removed,0);
 assert.equal(db.store.has('device_tokens/u/tokens/a'),true);
});

test('CR-02: splits 501 tokens and removes stale token from the correct chunk', async () => {
 const db=fakeDb(Object.fromEntries(Array.from({length:501},(_,i)=>['device_tokens/u/tokens/'+i,{token:'t'+i}])));
 const messaging=fakeMessaging({'t500':'messaging/registration-token-not-registered'});
 const send=messaging.sendEachForMulticast;
 messaging.sendEachForMulticast=async m=>{assert.ok(m.tokens.length<=500);return send(m);};
 const result=await pushToUser(deps(db,messaging),'u',{title:'x',body:'y'});
 assert.deepEqual(messaging.sent.map(m=>m.tokens.length),[500,1]);
 assert.deepEqual(result,{sent:500,failed:1,removed:1});
 assert.equal(db.store.has('device_tokens/u/tokens/500'),false);
});
test('CR-02: failed token deletion is not counted as removed', async () => {
 const db=fakeDb({'device_tokens/u/tokens/a':{token:'a'}});
 db.collection=()=>({get:async()=>({docs:[{data:()=>({token:'a'}),ref:{delete:async()=>{throw Error('offline');}}}]})});
 const result=await pushToUser(deps(db,fakeMessaging({'a':'messaging/registration-token-not-registered'})),'u',{title:'x',body:'y'});
 assert.equal(result.removed,0); assert.equal(result.failed,1);
});
