const { db } = require('../config/firestore');

async function resolveStudentId(studentIdInput) {
  const raw = String(studentIdInput || '').trim();
  if (!raw) {
    return null;
  }

  // 1) Direct document id match
  const directDoc = await db.collection('users').doc(raw).get();
  if (directDoc.exists) {
    return raw;
  }

  // 2) Match by explicit studentId field
  const byStudentId = await db
    .collection('users')
    .where('studentId', '==', raw)
    .limit(1)
    .get();
  if (!byStudentId.empty) {
    return byStudentId.docs[0].id;
  }

  // 3) Match by existing schema fields in your main app
  const byDigitalId = await db
    .collection('users')
    .where('digitalId', '==', raw)
    .limit(1)
    .get();
  if (!byDigitalId.empty) {
    return byDigitalId.docs[0].id;
  }

  const byRollNo = await db
    .collection('users')
    .where('rollNo', '==', raw)
    .limit(1)
    .get();
  if (!byRollNo.empty) {
    return byRollNo.docs[0].id;
  }

  return null;
}

module.exports = {
  resolveStudentId,
};
