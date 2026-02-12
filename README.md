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
