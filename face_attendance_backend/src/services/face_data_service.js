const { db, FieldValue } = require('../config/firestore');
const ApiError = require('../utils/api_error');
const { resolveStudentId } = require('./user_service');

function validateEmbedding(embedding) {
  if (!Array.isArray(embedding)) {
    throw new ApiError(400, 'INVALID_EMBEDDING', 'Embedding must be an array.');
  }

  if (embedding.length < 16) {
    throw new ApiError(
      400,
      'INVALID_EMBEDDING',
      'Embedding is too short. Ensure full face features are extracted.'
    );
  }

  const normalized = embedding.map((v) => Number(v));
  if (normalized.some((v) => !Number.isFinite(v))) {
    throw new ApiError(
      400,
      'INVALID_EMBEDDING',
      'Embedding contains non-numeric values.'
    );
  }

  return normalized;
}

async function registerFace(studentIdInput, embeddingInput) {
  const resolvedStudentId = await resolveStudentId(studentIdInput);
  if (!resolvedStudentId) {
    throw new ApiError(404, 'STUDENT_NOT_FOUND', 'studentId not found in users.');
  }

  const embedding = validateEmbedding(embeddingInput);
  const ref = db.collection('face_data').doc(resolvedStudentId);

  await db.runTransaction(async (tx) => {
    const snapshot = await tx.get(ref);
    if (snapshot.exists) {
      tx.update(ref, {
        embedding,
        updatedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    tx.set(ref, {
      studentId: resolvedStudentId,
      embedding,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  return { studentId: resolvedStudentId };
}

async function listFaceEmbeddings() {
  const snapshot = await db.collection('face_data').get();
  return snapshot.docs.map((doc) => {
    const data = doc.data() || {};
    return {
      studentId: data.studentId || doc.id,
      embedding: Array.isArray(data.embedding) ? data.embedding : [],
      createdAt: data.createdAt || null,
      updatedAt: data.updatedAt || null,
    };
  });
}

module.exports = {
  registerFace,
  listFaceEmbeddings,
};
