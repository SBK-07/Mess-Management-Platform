# Smart Mess Management System

A Flutter application for managing hostel mess operations including digital menu, complaint tracking, and staff management using Firebase.

## Setup Requirements

Before running the project, you must configure Firebase:

1. **Install Firebase CLI** (if not installed):
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   ```

2. **Login to Firebase**:
   ```bash
   firebase login
   ```

3. **Configure Project**:
   Run this command in the project root to connect to your Firebase project (`mess-management-platfrom`):
   ```bash
   flutterfire configure
   ```
   - Select your project (`mess-management-platfrom`)
   - Select platforms (Android, iOS, Web, macOS)
   - This will regenerate `lib/firebase_options.dart` with your real API keys.

## Running the App

After configuring Firebase:

```bash
flutter run
```

## Features

- **Authentication**: Role-based login (Student, Staff, Admin)
- **Admin Dashboard**:
  - Approve staff requests
  - Create student accounts
  - View complaint statistics
- **Student Features**:
  - View daily menu
  - Submit complaints (Taste, Hygiene, Quantity)
  - Select replacement food items
- **Staff Features**:
  - View menu (placeholder)
  - View complaints (placeholder)

## Repository Branch Structure (Git Flow)

| Branch | Purpose |
|---|---|
| `main` | Stable, production-ready code |
| `develop` | Integration branch for all features |
| `feature/user-management` | Login, signup, role-based access |
| `feature/menu-management` | Weekly menu, Firebase menu upload |
| `feature/feedback-processing` | Student feedback and ratings |
| `feature/replacement-management` | Meal replacement requests |
| `feature/leave-wastage` | Mess cancellation and wastage tracking |
| `feature/billing-management` | Billing and PDF export |
| `feature/analytics-reporting` | Admin analytics dashboard |
| `docs/srs` | SRS documentation |
| `docs/dfd-diagrams` | DFD Level-0, Level-1, Level-2 |

## Documentation

All assignment documents are located in the [`docs/`](docs/) directory:

- [`Assignment5_Git_VersionControl.md`](docs/Assignment5_Git_VersionControl.md) — Git & GitHub workflow (Assignment 5)

## Technology Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Backend | Firebase Firestore |
| Authentication | Firebase Auth + Google Sign-In |
| State Management | Provider |
| Version Control | Git + GitHub |
