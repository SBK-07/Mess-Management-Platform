const { db, FieldValue } = require('../config/firestore');
const ApiError = require('../utils/api_error');
const { getDateId, getMealByServerTime } = require('../utils/time_slots');
const { resolveStudentId } = require('./user_service');

async function markAttendance(studentIdInput) {
  const resolvedStudentId = await resolveStudentId(studentIdInput);
  if (!resolvedStudentId) {
    throw new ApiError(404, 'STUDENT_NOT_FOUND', 'studentId not found in users.');
  }

  const meal = getMealByServerTime(new Date());
  if (!meal) {
    throw new ApiError(
      400,
      'INVALID_TIME',
      'Attendance not allowed at this time.'
    );
  }

  const dateId = getDateId(new Date());
  const attendanceRef = db
    .collection('attendance')
    .doc(dateId)
    .collection('students')
    .doc(resolvedStudentId);

  await db.runTransaction(async (tx) => {
    const existing = await tx.get(attendanceRef);
    const data = existing.exists ? existing.data() || {} : {};

    if (data[meal] === true) {
      throw new ApiError(
        409,
        'DUPLICATE_ATTENDANCE',
        `Attendance already marked for ${meal}`
      );
    }

    tx.set(
      attendanceRef,
      {
        studentId: resolvedStudentId,
        breakfast: data.breakfast === true,
        lunch: data.lunch === true,
        dinner: data.dinner === true,
        [meal]: true,
        lastMarked: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });

  return {
    studentId: resolvedStudentId,
    meal,
    date: dateId,
  };
}

module.exports = {
  markAttendance,
};
