const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

function resolveProjectId() {
  return (
    process.env.FIREBASE_PROJECT_ID ||
    process.env.GOOGLE_CLOUD_PROJECT ||
    'mess-management-platform'
  );
}

function resolveCredential() {
  const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (!credentialsPath) {
    return admin.credential.applicationDefault();
  }

  const absolutePath = path.isAbsolute(credentialsPath)
    ? credentialsPath
    : path.resolve(process.cwd(), credentialsPath);

  if (!fs.existsSync(absolutePath)) {
    throw new Error(
      `GOOGLE_APPLICATION_CREDENTIALS file not found: ${absolutePath}`
    );
  }

  const serviceAccount = require(absolutePath);
  return admin.credential.cert(serviceAccount);
}

if (!admin.apps.length) {
  admin.initializeApp({
    credential: resolveCredential(),
    projectId: resolveProjectId(),
  });
}

const db = admin.firestore();

module.exports = {
  admin,
  db,
  FieldValue: admin.firestore.FieldValue,
};
