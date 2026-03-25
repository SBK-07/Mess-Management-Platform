# Face Attendance System Setup

## Modules Added

- `face_attendance_app/`: Separate Flutter app for face registration and attendance marking.
- `face_attendance_backend/`: Node.js Express API for face data storage and attendance validation.

## Firestore Structure

### 1) Face Embeddings

Collection: `face_data`

Document ID: `<studentId>`

Fields:
- `studentId`: string
- `embedding`: number[]
- `createdAt`: timestamp
- `updatedAt`: timestamp

### 2) Attendance

Collection: `attendance`

Document ID: `YYYY-MM-DD`

Subcollection: `students`

Document ID: `<studentId>`

Fields:
- `studentId`: string
- `breakfast`: boolean
- `lunch`: boolean
- `dinner`: boolean
- `lastMarked`: timestamp

## API Endpoints

### `POST /register-face`
Request:
```json
{
  "studentId": "STU001",
  "embedding": [0.12, 0.43, 0.88]
}
```

Response:
- Success: `FACE_REGISTERED`
- Error: `STUDENT_NOT_FOUND`, `INVALID_EMBEDDING`, `VALIDATION_ERROR`

### `GET /face-embeddings`
Response:
- Success: returns all `{ studentId, embedding }` records

### `POST /mark-attendance`
Request:
```json
{
  "studentId": "STU001"
}
```

Attendance windows (server time):
- Breakfast: 07:00-08:00
- Lunch: 12:00-13:00
- Dinner: 18:30-21:30

Response:
- Success: `ATTENDANCE_MARKED`
- Errors: `INVALID_TIME`, `DUPLICATE_ATTENDANCE`, `STUDENT_NOT_FOUND`

## Flutter Face App Flow

1. Open camera.
2. Detect exactly one face with `google_mlkit_face_detection`.
3. Build embedding vector from face geometry and landmarks.
4. Registration mode: send embedding and `studentId` to `/register-face`.
5. Attendance mode: fetch embeddings from `/face-embeddings`, perform cosine/euclidean matching, then call `/mark-attendance` with matched student.

## Run Backend

```bash
cd face_attendance_backend
npm install
cp .env.example .env
npm start
```

## Run Face App

```bash
cd face_attendance_app
flutter pub get
flutter run
```

Notes:
- In Android emulator, default backend base URL is `http://10.0.2.2:3000`.
- Ensure `GOOGLE_APPLICATION_CREDENTIALS` is set for local backend Firebase Admin access.
- `studentId` resolution supports direct user doc ID, `studentId`, `digitalId`, and `rollNo` fields from your existing `users` collection.
