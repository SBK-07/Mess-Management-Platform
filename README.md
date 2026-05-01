# Smart Mess Management Platform

<p align="center">
  <img src="assets/images/food_background.png" alt="Mess Management Platform Banner" width="600"/>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter"/></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" alt="Dart"/></a>
  <a href="https://firebase.google.com"><img src="https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth%20%7C%20Storage-FFCA28?logo=firebase&logoColor=black" alt="Firebase"/></a>
  <a href="https://nodejs.org"><img src="https://img.shields.io/badge/Node.js-Express-339933?logo=node.js&logoColor=white" alt="Node.js"/></a>
  <a href="https://pub.dev/packages/google_mlkit_face_detection"><img src="https://img.shields.io/badge/ML%20Kit-Face%20Detection-4285F4?logo=google&logoColor=white" alt="ML Kit"/></a>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey?logo=flutter" alt="Platform"/>
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License"/>
</p>

A **production-oriented, full-stack hostel mess management system** built with Flutter and Firebase. The platform digitises the complete lifecycle of institutional mess operations — from menu publishing and complaint tracking to face-recognition-based attendance and automated billing — replacing paper-based workflows with a role-gated, real-time application.

---

## Table of Contents

1. [Problem Statement / Objective](#problem-statement--objective)
2. [Features](#features)
3. [Tech Stack](#tech-stack)
4. [System Architecture / Workflow](#system-architecture--workflow)
5. [Installation & Setup](#installation--setup)
6. [Usage](#usage)
7. [Screenshots / Demo](#screenshots--demo)
8. [API Integration](#api-integration)
9. [Folder Structure](#folder-structure)
10. [Future Enhancements / Roadmap](#future-enhancements--roadmap)
11. [Contributing](#contributing)
12. [License](#license)
13. [Author / Contact](#author--contact)

---

## Problem Statement / Objective

Residential hostels and university campuses rely on manual, error-prone processes for mess management: printed menus, paper complaint registers, manual attendance sheets, and spreadsheet-driven billing. This creates:

- **Operational inefficiencies** — staff spend significant time on repetitive administrative tasks.
- **Lack of transparency** — students have no real-time visibility into menus, complaints, or billing.
- **Data silos** — no consolidated view of food quality trends or attendance patterns for administrators.
- **Fraud risk** — manual attendance is susceptible to proxy entries.

**Objective:** Build a multi-role, real-time platform that automates mess operations, enforces role-based access control, provides data-driven analytics, and integrates face-recognition biometrics to eliminate proxy attendance.

---

## Features

### 🔐 Authentication & Role-Based Access Control
- Email/password and **Google Sign-In** via Firebase Authentication.
- Three distinct roles: **Admin**, **Staff**, and **Student** — each with isolated navigation and Firestore security rule enforcement.
- Staff accounts require admin approval before activation; pending users are held at a waiting screen.

### 👨‍💼 Admin Dashboard
- **Staff management** — approve/reject staff registration requests.
- **Student account creation** — individual or **bulk CSV import** with validation.
- **Weekly menu management** — publish and edit the 7-day meal plan per meal slot.
- **Complaint analytics** — view aggregated complaint trends with severity classification (low/medium/high) and repeated-issue alerting.
- **Mess cancellation oversight** — review and manage student cancellation requests.
- **Billing generation** — calculate and publish monthly bills per student based on actual attendance.

### 👷 Staff Portal
- Real-time view of today's menu and upcoming meal schedule.
- Student management — view enrolled students and their attendance records.
- Operational snapshot — today's food reports, low-rating meals, and repeated issue alerts.
- Billing interface — view and mark student bills as paid.

### 🎓 Student Portal
- **Daily & weekly menu viewer** — browse the full weekly meal plan with meal-type filtering.
- **Complaint / food report submission** — categorised by meal type and issue type (taste, hygiene, temperature, portion size, quality, freshness, service).
- **Mess cancellation** — request meal cancellations to adjust billing.
- **Replacement food selection** — choose substitute items when a menu item is unavailable.
- **Monthly bill tracking** — view current and historical billing statements.
- **Personal analytics** — view own attendance and meal history.

### 🤖 Face Recognition Attendance (Sub-system)
- Dedicated Flutter app (`face_attendance_app`) integrates **Google ML Kit Face Detection**.
- On-device face detection + embedding extraction from face geometry and landmarks.
- Cosine/Euclidean similarity matching against stored embeddings for identity verification.
- Node.js Express backend (`face_attendance_backend`) handles embedding storage (Firestore) and time-window-validated attendance marking (Breakfast / Lunch / Dinner slots).

### 📊 Analytics Dashboard
- Interactive charts powered by **fl_chart** for complaint trends, attendance statistics, and meal ratings.
- Configurable date-range and meal/issue-type filters.
- Adjustable severity thresholds for repeated-issue detection.
- Export capabilities for reporting.

---

## Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| **Frontend** | Flutter 3.x (Dart) | Cross-platform UI for Android, iOS, Web |
| **State Management** | Provider | Application-wide state (auth, menu, analytics) |
| **Authentication** | Firebase Authentication | Email/password + Google Sign-In |
| **Database** | Cloud Firestore | Real-time NoSQL data store |
| **File Storage** | Firebase Storage | Profile images and document uploads |
| **Backend API** | Node.js + Express | Face attendance REST API |
| **Face Recognition** | Google ML Kit (Face Detection) | On-device face detection & embedding |
| **Charts** | fl_chart | Analytics visualisations |
| **PDF Generation** | Syncfusion Flutter PDF | Report and bill exports |
| **Excel Handling** | excel (Dart) | Bulk student CSV import |
| **Fonts** | Google Fonts | UI typography |
| **Build Tooling** | FlutterFire CLI, Firebase CLI | Firebase project configuration |
| **Security Rules** | Firestore Security Rules | Role-enforced data access |

---

## System Architecture / Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Application                       │
│  ┌──────────┐  ┌──────────┐  ┌────────────┐               │
│  │  Admin   │  │  Staff   │  │  Student   │  (Role Router) │
│  │ Dashboard│  │  Portal  │  │   Portal   │               │
│  └────┬─────┘  └────┬─────┘  └─────┬──────┘               │
│       └─────────────┴──────────────┘                        │
│                    Provider (AppState)                       │
│              Services Layer (Auth, Menu, Billing …)         │
└─────────────────────────┬───────────────────────────────────┘
                           │ Firebase SDK
         ┌─────────────────┼──────────────────┐
         │                 │                  │
  ┌──────▼──────┐  ┌───────▼──────┐  ┌───────▼──────┐
  │  Firebase   │  │  Cloud       │  │  Firebase    │
  │    Auth     │  │  Firestore   │  │   Storage    │
  └─────────────┘  └──────────────┘  └──────────────┘

                  Face Attendance Sub-system
  ┌──────────────────────┐      ┌──────────────────────────┐
  │  face_attendance_app │ HTTP │  face_attendance_backend  │
  │  (Flutter + ML Kit)  │─────▶│  (Node.js + Express)     │
  │  On-device detection │      │  Firestore Admin SDK     │
  └──────────────────────┘      └──────────────────────────┘
```

### Authentication & Role Routing Flow

```
Login ──► Firebase Auth ──► Firestore user doc
                                  │
               ┌──────────────────┼──────────────────┐
               ▼                  ▼                  ▼
           role=admin         role=staff         role=student
           approved=true      approved=true
               │                  │                  │
        AdminDashboard      StaffHomeScreen      HomeScreen
```

### Firestore Data Model

| Collection | Document | Key Fields |
|---|---|---|
| `users` | `{uid}` | `role`, `approved`, `studentId`, `rollNo` |
| `mess_menu` | `{weekday_meal}` | `items[]`, `date`, `mealType` |
| `complaints` | `{id}` | `studentId`, `mealType`, `issueType`, `rating`, `timestamp` |
| `cancellations` | `{id}` | `studentId`, `date`, `mealType`, `status` |
| `attendance` | `{YYYY-MM-DD}` → `students/{studentId}` | `breakfast`, `lunch`, `dinner`, `lastMarked` |
| `billing` | `{YYYY-MM}/{studentId}` | `chargedDays`, `amount`, `isPaid`, `paidAt` |
| `face_data` | `{studentId}` | `embedding[]`, `createdAt`, `updatedAt` |

---

## Installation & Setup

### Prerequisites

| Tool | Version |
|---|---|
| Flutter SDK | ≥ 3.x |
| Dart SDK | ≥ 3.x |
| Node.js | ≥ 18.x (for face backend) |
| Firebase CLI | Latest |
| FlutterFire CLI | Latest |

### 1. Clone the Repository

```bash
git clone https://github.com/SBK-07/Mess-Management-Platform.git
cd Mess-Management-Platform
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

**Install CLI tools (if not already installed):**
```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

**Authenticate and link your Firebase project:**
```bash
firebase login
flutterfire configure
```
- Select (or create) your Firebase project.
- Select target platforms: Android, iOS, Web, macOS.
- This generates `lib/firebase_options.dart` with your project credentials.

**Deploy Firestore security rules:**
```bash
firebase deploy --only firestore:rules
```

### 4. Set Up the Face Attendance Backend

```bash
cd face_attendance_backend
npm install
cp .env.example .env
# Edit .env: set GOOGLE_APPLICATION_CREDENTIALS to your Firebase service account JSON path
npm start
```

The API will be available at `http://localhost:3000`.

### 5. Run the Main Application

```bash
# From the project root
flutter run
```

For web:
```bash
flutter run -d chrome
```

### 6. Run the Face Attendance App (Optional)

```bash
cd face_attendance_app
flutter pub get
flutter run
# Default backend URL for Android emulator: http://10.0.2.2:3000
```

---

## Usage

### Admin Workflow
1. Log in with an admin account. A local development bootstrap account can be configured in `lib/services/auth_service.dart` — **do not use or commit real credentials; replace this with a proper admin seeding process before deploying to production**.
2. Navigate to the **Staff Requests** tab to approve pending staff registrations.
3. Use the **Students** tab to create accounts individually or upload a CSV for bulk import.
4. Publish the weekly menu from the **Menu** tab.
5. Monitor complaints and analytics from the **Analytics** tab.
6. Generate and manage monthly billing from the **Billing** tab.

### Staff Workflow
1. Log in — account requires prior admin approval.
2. View today's menu and upcoming meals on the home screen.
3. Review student complaints and food reports.
4. Mark student bills as paid from the billing screen.

### Student Workflow
1. Register with an institutional email and complete your profile.
2. Browse the daily/weekly menu from the home screen.
3. Submit a food report or complaint after a meal.
4. Request a mess cancellation for planned absences.
5. Track your monthly bill and payment status.

### Face Attendance (Biometric)
1. Launch `face_attendance_app` on a device with a camera.
2. **Registration mode** — enrol a student's face: the app captures a frame, detects the face, extracts an embedding, and sends it to `/register-face`.
3. **Attendance mode** — at meal time, the app matches the live face against stored embeddings and calls `/mark-attendance`. The backend validates the current time against meal windows before recording.

---

## Screenshots / Demo

> _Screenshots are located in `assets/images/`. Add UI screenshots below by placing image files in that directory and updating the paths._

| Screen | Description |
|---|---|
| Login | Role-based login with Google Sign-In support |
| Admin Dashboard | Tabbed view: Overview, Staff, Students, Menu, Analytics |
| Student Home | Daily menu, quick actions (complaint, cancellation) |
| Analytics Dashboard | Charts for complaint trends, attendance stats, meal ratings |
| Face Attendance App | Camera-based face detection and attendance marking |

---

## API Integration

The **Face Attendance REST API** (`face_attendance_backend`) exposes the following endpoints:

### Base URL

| Environment | URL |
|---|---|
| Local (Node.js) | `http://localhost:3000` |
| Android Emulator | `http://10.0.2.2:3000` |
| Production | Configure via the `FACE_BACKEND_URL` environment variable or equivalent app constant |

### Endpoints

#### `GET /health`
Health check.
```json
{ "success": true, "code": "OK", "message": "Face attendance API is running." }
```

#### `POST /register-face`
Register a student's face embedding.

**Request:**
```json
{
  "studentId": "STU001",
  "embedding": [0.12, 0.43, 0.88, "..."]
}
```
**Success Response:** `FACE_REGISTERED`  
**Error Codes:** `STUDENT_NOT_FOUND`, `INVALID_EMBEDDING`, `VALIDATION_ERROR`

#### `GET /face-embeddings`
Retrieve all registered face embeddings for client-side matching.

**Success Response:** `EMBEDDINGS_FETCHED` with `{ records: [{ studentId, embedding }] }`

#### `POST /mark-attendance`
Mark attendance for a student within a valid meal time window.

**Request:**
```json
{ "studentId": "STU001" }
```

**Meal Time Windows (server time):**

> These windows are defined in `face_attendance_backend/src/utils/time_slots.js` and can be adjusted to match institutional requirements.

| Meal | Window |
|---|---|
| Breakfast | 07:00 – 08:00 |
| Lunch | 12:00 – 13:00 |
| Dinner | 18:30 – 21:30 |

**Success Response:** `ATTENDANCE_MARKED`  
**Error Codes:** `INVALID_TIME`, `DUPLICATE_ATTENDANCE`, `STUDENT_NOT_FOUND`

### Firebase Services Used

| Service | Usage |
|---|---|
| Firebase Authentication | User sign-up, login, Google OAuth |
| Cloud Firestore | All application data (users, menu, complaints, billing, attendance) |
| Firebase Storage | Profile images, uploaded documents |
| Firebase Admin SDK | Server-side Firestore access in the Node.js backend |

---

## Folder Structure

```
Mess-Management-Platform/
├── lib/                          # Main Flutter application source
│   ├── main.dart                 # App entry point, route definitions
│   ├── firebase_options.dart     # Firebase project configuration
│   ├── providers/
│   │   └── app_state.dart        # Global state (ChangeNotifier)
│   ├── models/                   # Data models
│   │   ├── user.dart             # AppUser with role/approval fields
│   │   ├── menu_item.dart
│   │   ├── complaint.dart
│   │   ├── cancellation.dart
│   │   ├── replacement.dart
│   │   └── ...
│   ├── services/                 # Business logic & Firestore operations
│   │   ├── auth_service.dart     # Firebase Auth + Google Sign-In
│   │   ├── menu_service.dart
│   │   ├── complaint_service.dart
│   │   ├── cancellation_service.dart
│   │   ├── mess_billing_service.dart
│   │   ├── analytics_service.dart
│   │   ├── bulk_import_service.dart
│   │   └── notification_service.dart
│   ├── repositories/             # Firestore data access layer
│   ├── screens/                  # UI screens per role
│   │   ├── login_screen.dart
│   │   ├── admin_dashboard.dart
│   │   ├── staff_home_screen.dart
│   │   ├── home_screen.dart      # Student home
│   │   ├── analytics_dashboard_screen.dart
│   │   └── ...
│   ├── widgets/                  # Reusable UI components
│   └── utils/                    # Constants, helpers, upload utilities
│
├── face_attendance_app/          # Standalone face attendance Flutter app
│   └── lib/                      # ML Kit camera + embedding logic
│
├── face_attendance_backend/      # Node.js REST API
│   └── src/
│       ├── server.js             # Express app, route definitions
│       ├── services/
│       │   ├── attendance_service.js
│       │   ├── face_data_service.js
│       │   └── user_service.js
│       ├── config/               # Firebase Admin SDK initialisation
│       └── utils/
│
├── assets/images/                # App image assets
├── docs/                         # Setup guides and documentation
├── firestore.rules               # Firestore role-based security rules
├── firestore.indexes.json        # Composite index definitions
├── firebase.json                 # Firebase CLI project configuration
└── pubspec.yaml                  # Flutter dependencies
```

---

## Future Enhancements / Roadmap

| Priority | Enhancement | Description |
|---|---|---|
| 🔴 High | Push Notifications | Firebase Cloud Messaging for menu updates, complaint responses, bill reminders |
| 🔴 High | Tighten Firestore Rules | Replace the broad authenticated catch-all rule with per-collection, per-role rules |
| 🟡 Medium | Face Embedding Security | Encrypt embeddings at rest; rate-limit the `/face-embeddings` endpoint |
| 🟡 Medium | QR-Code Meal Tokens | Alternative to face recognition for faster meal-time check-in |
| 🟡 Medium | Offline Support | Firestore offline persistence for low-connectivity environments |
| 🟢 Low | Payment Gateway Integration | Razorpay / Stripe for in-app mess bill payments |
| 🟢 Low | Multi-Mess Support | Multi-tenancy to support multiple hostels/messes per institution |
| 🟢 Low | Dietary Preferences | Student-configurable dietary flags (vegetarian, vegan, allergens) |
| 🟢 Low | NLP Complaint Analysis | Sentiment analysis on free-text complaint descriptions |
| 🟢 Low | CI/CD Pipeline | GitHub Actions for automated Flutter build, lint, and test |

---

## Contributing

Contributions, issues, and feature requests are welcome.

1. **Fork** the repository.
2. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Commit your changes** with a descriptive message:
   ```bash
   git commit -m "feat: add QR code meal token support"
   ```
4. **Push** to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```
5. **Open a Pull Request** against `main`, describing your changes and the motivation.

### Code Style
- Follow the [Dart style guide](https://dart.dev/guides/language/effective-dart/style) and existing `analysis_options.yaml` lint rules.
- Run `flutter analyze` before submitting.
- For the Node.js backend, follow the ESLint rules in `package.json`.

---

## License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## Author / Contact

**Suraj B K**  
GitHub: [@SBK-07](https://github.com/SBK-07)

---

<p align="center">
  Built with ❤️ using Flutter &amp; Firebase
</p>
