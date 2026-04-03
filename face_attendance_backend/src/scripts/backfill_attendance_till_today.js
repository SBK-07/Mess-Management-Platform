const { db, admin } = require('../config/firestore');

const BATCH_LIMIT = 450;

function parseArgs(argv) {
  const parsed = {
    startDate: process.env.START_DATE || '2026-01-01',
    studentId: process.env.STUDENT_ID || null,
    dryRun: false,
  };

  for (const arg of argv) {
    if (arg.startsWith('--startDate=')) {
      parsed.startDate = arg.split('=')[1];
      continue;
    }
    if (arg.startsWith('--studentId=')) {
      parsed.studentId = arg.split('=')[1];
      continue;
    }
    if (arg === '--dryRun') {
      parsed.dryRun = true;
    }
  }

  return parsed;
}

function parseDateId(dateId) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(dateId)) {
    throw new Error(`Invalid date format: ${dateId}. Expected YYYY-MM-DD`);
  }
  const [y, m, d] = dateId.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d));
}

function formatDateId(date) {
  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, '0');
  const d = String(date.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

function hashToUnit(str) {
  let hash = 2166136261;
  for (let i = 0; i < str.length; i++) {
    hash ^= str.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return ((hash >>> 0) % 10000) / 10000;
}

function attendanceFor(studentId, dateId) {
  const b = hashToUnit(`${studentId}-${dateId}-b`) < 0.72;
  const l = hashToUnit(`${studentId}-${dateId}-l`) < 0.86;
  const d = hashToUnit(`${studentId}-${dateId}-d`) < 0.80;

  if (!b && !l && !d) {
    return { breakfast: false, lunch: true, dinner: false };
  }
  return { breakfast: b, lunch: l, dinner: d };
}

function lastMarkedFor(dateId, attendance, studentId) {
  const base = parseDateId(dateId);
  const minuteOffset = Math.floor(hashToUnit(`${studentId}-${dateId}-m`) * 25);

  if (attendance.dinner) {
    return new Date(
      Date.UTC(
        base.getUTCFullYear(),
        base.getUTCMonth(),
        base.getUTCDate(),
        20,
        5 + minuteOffset,
        0,
      ),
    );
  }
  if (attendance.lunch) {
    return new Date(
      Date.UTC(
        base.getUTCFullYear(),
        base.getUTCMonth(),
        base.getUTCDate(),
        13,
        10 + minuteOffset,
        0,
      ),
    );
  }
  return new Date(
    Date.UTC(
      base.getUTCFullYear(),
      base.getUTCMonth(),
      base.getUTCDate(),
      8,
      10 + minuteOffset,
      0,
    ),
  );
}

async function fetchStudentIds(singleStudentId) {
  if (singleStudentId) {
    const doc = await db.collection('users').doc(singleStudentId).get();
    if (!doc.exists) {
      throw new Error(`Student not found in users collection: ${singleStudentId}`);
    }
    return [singleStudentId];
  }

  const usersSnapshot = await db.collection('users').get();
  const ids = [];
  for (const doc of usersSnapshot.docs) {
    const data = doc.data() || {};
    const role = String(data.role || '').toLowerCase();
    const hasStudentMarkers =
      data.isStudent === true ||
      typeof data.rollNo === 'string' ||
      typeof data.studentId === 'string';

    if (role === 'student' || hasStudentMarkers) {
      ids.push(doc.id);
    }
  }

  return [...new Set(ids)].sort();
}

async function backfillAttendance({ startDate, studentId, dryRun }) {
  const start = parseDateId(startDate);
  const today = new Date();
  const end = new Date(Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate()));

  if (start > end) {
    throw new Error(`startDate ${startDate} cannot be in the future.`);
  }

  const studentIds = await fetchStudentIds(studentId);
  if (studentIds.length === 0) {
    console.log('No student IDs found. Nothing to backfill.');
    return;
  }

  console.log(`Students targeted: ${studentIds.length}`);
  console.log(`Date range: ${startDate} -> ${formatDateId(end)}`);
  if (dryRun) {
    console.log('Running in dry-run mode: no writes will be committed.');
  }

  let batch = db.batch();
  let pendingOps = 0;
  let created = 0;
  let skippedExisting = 0;

  async function commitIfNeeded(force = false) {
    if (!force && pendingOps < BATCH_LIMIT) {
      return;
    }
    if (pendingOps === 0) {
      return;
    }
    if (!dryRun) {
      await batch.commit();
    }
    batch = db.batch();
    pendingOps = 0;
  }

  for (
    let day = new Date(start);
    day <= end;
    day = new Date(day.getTime() + 24 * 60 * 60 * 1000)
  ) {
    const dateId = formatDateId(day);
    const studentsRef = db.collection('attendance').doc(dateId).collection('students');
    const existingSnapshot = await studentsRef.get();
    const existingIds = new Set(existingSnapshot.docs.map((doc) => doc.id));

    for (const sid of studentIds) {
      if (existingIds.has(sid)) {
        skippedExisting++;
        continue;
      }

      const attendance = attendanceFor(sid, dateId);
      const lastMarked = lastMarkedFor(dateId, attendance, sid);

      const docRef = studentsRef.doc(sid);
      batch.set(
        docRef,
        {
          studentId: sid,
          breakfast: attendance.breakfast,
          lunch: attendance.lunch,
          dinner: attendance.dinner,
          lastMarked: admin.firestore.Timestamp.fromDate(lastMarked),
        },
        { merge: true },
      );

      pendingOps++;
      created++;
      await commitIfNeeded();
    }
  }

  await commitIfNeeded(true);

  console.log(`Created records: ${created}`);
  console.log(`Skipped existing: ${skippedExisting}`);
  console.log('Backfill completed.');
}

async function main() {
  try {
    const args = parseArgs(process.argv.slice(2));
    await backfillAttendance(args);
    process.exit(0);
  } catch (error) {
    console.error('Backfill failed:', error.message || error);
    process.exit(1);
  }
}

main();
