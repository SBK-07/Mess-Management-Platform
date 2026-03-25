require('dotenv').config();

const express = require('express');
const cors = require('cors');

const ApiError = require('./utils/api_error');
const { markAttendance } = require('./services/attendance_service');
const { registerFace, listFaceEmbeddings } = require('./services/face_data_service');

const app = express();
app.use(cors());
app.use(express.json({ limit: '2mb' }));

app.get('/health', (_req, res) => {
  return res.status(200).json({
    success: true,
    code: 'OK',
    message: 'Face attendance API is running.',
  });
});

app.post('/register-face', async (req, res, next) => {
  try {
    const { studentId, embedding } = req.body || {};
    if (!studentId) {
      throw new ApiError(400, 'VALIDATION_ERROR', 'studentId is required.');
    }

    const result = await registerFace(studentId, embedding);
    return res.status(200).json({
      success: true,
      code: 'FACE_REGISTERED',
      message: `Face registered for ${result.studentId}`,
      data: result,
    });
  } catch (error) {
    return next(error);
  }
});

app.get('/face-embeddings', async (_req, res, next) => {
  try {
    const records = await listFaceEmbeddings();
    return res.status(200).json({
      success: true,
      code: 'EMBEDDINGS_FETCHED',
      message: 'Face embeddings fetched successfully.',
      data: { records },
    });
  } catch (error) {
    return next(error);
  }
});

app.post('/mark-attendance', async (req, res, next) => {
  try {
    const { studentId } = req.body || {};
    if (!studentId) {
      throw new ApiError(400, 'VALIDATION_ERROR', 'studentId is required.');
    }

    const result = await markAttendance(studentId);
    return res.status(200).json({
      success: true,
      code: 'ATTENDANCE_MARKED',
      message: `Attendance marked successfully for ${result.meal}`,
      data: result,
    });
  } catch (error) {
    return next(error);
  }
});

app.use((error, _req, res, _next) => {
  const statusCode = error.statusCode || 500;
  const code = error.code || 'INTERNAL_ERROR';
  const message = error.message || 'Unexpected server error.';

  return res.status(statusCode).json({
    success: false,
    code,
    message,
  });
});

const port = Number(process.env.PORT || 3000);
app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`Face attendance API listening on port ${port}`);
});
