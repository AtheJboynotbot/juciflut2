# JuCi Faculty Portal

> **This project is no longer operational.** The Firebase (Firestore) backend subscription has been cancelled and the database has been shut down. All server-dependent features — authentication, schedule management, bookings, and profile management — **will not function**. This repository is preserved for **reference and portfolio purposes only.**

---

## About

**JuCi Faculty Portal** is a Flutter web application built for JuCi University to streamline faculty consultation scheduling. Faculty members can manage their availability, consultation schedules, and student booking requests from a single dashboard.

The app was built as a school project and relied on **Google Firebase** for its entire backend (authentication, database, storage, analytics, and crash reporting).

---

## Features

- **Google Sign-In Authentication** — Faculty log in with their institutional Google accounts.
- **Dashboard** — Overview of upcoming consultations, bookings, and quick stats.
- **Schedule Management** — Create, edit, and delete consultation/class/meeting/office-hours time slots with a calendar view.
- **Booking System** — Students request consultation slots; faculty approve, reject, or cancel.
- **Profile Management** — Update name, department, office location, availability status, etc.
- **Analytics & Crashlytics** — Firebase Analytics for usage tracking; Crashlytics for error reporting (mobile only).
- **Multi-Environment Support** — Separate configs for dev, staging, and production via `.env` files.

---

## Tech Stack

| Layer         | Technology                                                |
|---------------|-----------------------------------------------------------|
| Framework     | Flutter (Dart) — Web-first                                |
| Auth          | Firebase Authentication + Google Sign-In                  |
| Database      | Cloud Firestore (named database: `facconsult-firebase`)   |
| Storage       | Firebase Storage (profile images)                         |
| Analytics     | Firebase Analytics                                        |
| Crash Reports | Firebase Crashlytics                                      |
| State Mgmt    | Provider                                                  |
| Env Config    | flutter_dotenv                                            |
| Calendar      | table_calendar                                            |

---

## Project Structure

```
juciflut/
├── lib/
│   ├── main.dart                  # App entry point & Firebase init
│   ├── firebase_options.dart      # Environment-aware Firebase config
│   ├── models/                    # Data models (Faculty, Booking, Schedule)
│   ├── providers/                 # State management (FacultyProvider, BookingProvider)
│   ├── services/                  # Business logic (Auth, Booking, Analytics)
│   ├── utils/                     # Helpers (logger, time utilities, validators)
│   └── views/                     # UI screens & pages
│       ├── web_login_screen.dart
│       ├── dashboard_shell.dart
│       └── pages/
│           ├── dashboard_page.dart
│           ├── schedule_page.dart
│           ├── schedule_details_screen.dart
│           ├── bookings_page.dart
│           └── profile_page.dart
├── test/                          # Unit & widget tests
├── integration_test/              # Integration tests
├── assets/images/                 # App logos and images
├── firestore.rules                # Firestore security rules
├── firebase.json                  # Firebase project config
├── .env.example                   # Environment variable template
└── pubspec.yaml                   # Dependencies
```

---

## Prerequisites

Before you begin, make sure you have the following installed:

1. **Flutter SDK** version **3.10.7 or higher** — [Install Flutter](https://docs.flutter.dev/get-started/install)
2. **Git** — [Download Git](https://git-scm.com/downloads)
3. **Google Chrome** or **Microsoft Edge** (the app runs in the browser)
4. **A Firebase project** (see [Firebase Setup](#step-3-set-up-firebase-required-for-the-app-to-function) below)

Verify Flutter is installed correctly by running:

```powershell
flutter doctor
```

You should see a green checkmark next to "Flutter" and "Chrome" (or "Edge").

---

## How to Run (Step by Step)

### Step 1: Clone the Repository

```powershell
git clone https://github.com/<your-username>/juciflut.git
cd juciflut
```

### Step 2: Install Dependencies

```powershell
flutter pub get
```

This downloads all required Dart/Flutter packages listed in `pubspec.yaml`.

### Step 3: Set Up Firebase (required for the app to function)

The app **cannot run** without a valid Firebase backend. You need to either have access to the original Firebase project credentials or create a new one.

#### Option A — Use existing credentials (if you have them)

Copy the provided `.env` file into the project root. That's it — skip to Step 4.

#### Option B — Create a new Firebase project from scratch

1. Go to [console.firebase.google.com](https://console.firebase.google.com) and create a new project.
2. **Enable Authentication** → Sign-in method → Google.
3. **Create a Cloud Firestore database**.
   - If using a named database, note the database ID (default was `facconsult-firebase`).
4. **Enable Firebase Storage**.
5. Register a **Web app** in your Firebase project and note the config values.
6. Deploy the security rules from the file `firestore.rules` in this repo.
7. Manually add faculty documents to the `faculty` collection (self-registration is disabled by design).

### Step 4: Configure Environment Variables

```powershell
Copy-Item .env.example .env
```

Open `.env` in a text editor and replace every placeholder with your real Firebase credentials:

```
ENVIRONMENT=dev
FIREBASE_API_KEY_WEB=<your_web_api_key>
FIREBASE_APP_ID_WEB=<your_web_app_id>
FIREBASE_MESSAGING_SENDER_ID=<your_sender_id>
FIREBASE_PROJECT_ID=<your_project_id>
FIREBASE_AUTH_DOMAIN=<your_project_id>.firebaseapp.com
FIREBASE_STORAGE_BUCKET=<your_project_id>.firebasestorage.app
FIREBASE_DATABASE_ID=facconsult-firebase
```

All required variables are documented in `.env.example`.

### Step 5: Run the App

```powershell
# Launch in Microsoft Edge
flutter run -d edge

# — OR — launch in Google Chrome
flutter run -d chrome
```

The app will compile and open in your browser. You should see the **login screen**.

### Step 6: Log In

Sign in with a Google account whose email matches a document in the Firestore `faculty` collection. If no matching document exists, you will not be able to access the dashboard.

---

## Switching Environments

The app supports multiple environments via `.env` files:

| File           | Purpose              |
|----------------|----------------------|
| `.env`         | Active configuration |
| `.env.dev`     | Development          |
| `.env.staging` | Staging / QA         |
| `.env.prod`    | Production           |

To switch, either:

- **Copy** the desired file: `Copy-Item .env.staging .env -Force`
- **Or edit** `lib/main.dart` line 30 to load a different file:
  ```dart
  await dotenv.load(fileName: ".env.staging");
  ```

> Hot reload (`r`) does **not** reload `.env` files. You must fully restart the app (`R` or re-run `flutter run`).

---

## Building for Production

```powershell
# Option 1: Use the provided build script
.\build-prod.ps1

# Option 2: Manual steps
Copy-Item .env.prod .env -Force
flutter build web --release
# Output is in build/web/
```

---

## Running Tests

```powershell
# Run all unit & widget tests
flutter test

# Run a specific test file
flutter test test/models/faculty_model_test.dart

# Run integration tests
flutter test integration_test/
```

---

## Why This Project No Longer Works

This application's backend was powered entirely by **Google Firebase**. The Firebase plan associated with this project has been **cancelled** and the Firestore database has been **shut down**.

**What this means:**

- **Authentication fails** — Google Sign-In cannot validate against the deleted Firebase project.
- **Data reads/writes fail** — The Firestore database no longer exists.
- **File uploads fail** — Firebase Storage is no longer available.
- **Analytics & Crashlytics are inactive** — The Firebase project no longer accepts events.

**To restore functionality**, create a new Firebase project and update the `.env` credentials as described in [Step 3](#step-3-set-up-firebase-required-for-the-app-to-function) above.

---

## Author

**Albert John A. Judaya**

---

*This project was developed as a school project for JuCi University. It is no longer actively maintained.*
