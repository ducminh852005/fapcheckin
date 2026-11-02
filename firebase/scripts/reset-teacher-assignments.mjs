// Preview by default; --apply resets assignments only, never deletes records.
import { connect, parseArgs } from './lib.mjs';

const args = parseArgs();
const member = args.member;
if (typeof member !== 'string' || !member.trim()) {
  throw new Error('Required: --member <teacherMemberCode>');
}
const { db, projectId } = connect(args);
const targets = [];
for (const collection of ['classes', 'enrollments']) {
  const result = await db.collection(collection)
    .where('teacherMemberCode', '==', member).get();
  console.log(`${collection}: ${result.size} matching documents`);
  targets.push(...result.docs);
}
console.log(JSON.stringify({ projectId, member, apply: args.apply === true,
  classes: targets.filter(d => d.ref.parent.id === 'classes').map(d => d.id) }, null, 2));
if (args.apply === true) {
  // One atomic batch: do not leave half of a teacher's assignments reset.
  if (targets.length > 500) {
    throw new Error('More than 500 documents; no changes made. Requires a planned multi-batch reset.');
  }
  if (targets.length) {
    const batch = db.batch();
    for (const doc of targets) {
      batch.update(doc.ref, { teacherMemberCode: '' }, { lastUpdateTime: doc.updateTime });
    }
    await batch.commit();
  }
  console.log(`Reset ${targets.length} documents. Accounts and attendance history unchanged.`);
} else {
  console.log('Preview only. Add --apply to reset these assignments.');
}
