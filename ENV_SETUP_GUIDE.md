# Environment Configuration Guide - JuCi Faculty Portal

## Overview
This guide explains how to set up and use environment-specific configuration for the JuCi Faculty Portal using `flutter_dotenv`.

---

## 📦 What's Been Set Up

### 1. **Package Added**
- `flutter_dotenv: ^5.1.0` - Manages environment variables

### 2. **Environment Files Created**
- `.env` - Default environment (currently points to dev)
- `.env.dev` - Development environment
- `.env.staging` - Staging environment
- `.env.prod` - Production environment
- `.env.example` - Template for team reference

### 3. **Updated Files**
- `pubspec.yaml` - Added flutter_dotenv dependency and .env assets
- `lib/firebase_options.dart` - Modified to use environment variables
- `lib/main.dart` - Loads environment variables on startup
- `.gitignore` - Excludes .env files from version control

---

## 🚀 Quick Start

### Step 1: Install Dependencies
```powershell
flutter pub get
```

### Step 2: Verify .env Files Exist
Check that you have these files in your project root:
```
juciflut/
├── .env
├── .env.dev
├── .env.staging
├── .env.prod
└── .env.example
```

### Step 3: Run the App
```powershell
# Development (uses .env by default)
flutter run -d edge

# Or specify explicitly
flutter run -d edge --dart-define=ENVIRONMENT=dev
```

---

## 🔧 Switching Environments

### Method 1: Change .env File Reference (Recommended)

Edit `lib/main.dart` line 22:

**For Development:**
```dart
await dotenv.load(fileName: ".env.dev");
```

**For Staging:**
```dart
await dotenv.load(fileName: ".env.staging");
```

**For Production:**
```dart
await dotenv.load(fileName: ".env.prod");
```

### Method 2: Copy Environment File

Copy the environment you want to use over the default `.env`:

```powershell
# Windows PowerShell
# For staging
Copy-Item .env.staging .env

# For production
Copy-Item .env.prod .env
```

### Method 3: Build-Time Configuration

For release builds, you can specify the environment at build time by modifying your build script to copy the appropriate `.env` file before building.

---

## 📋 Environment Variables Reference

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `ENVIRONMENT` | Current environment | `dev`, `staging`, `prod` |
| `FIREBASE_API_KEY_WEB` | Firebase Web API Key | `AIzaSy...` |
| `FIREBASE_APP_ID_WEB` | Firebase Web App ID | `1:614451...` |
| `FIREBASE_MESSAGING_SENDER_ID` | Firebase Messaging Sender ID | `614451079097` |
| `FIREBASE_PROJECT_ID` | Firebase Project ID | `facconsult-19071` |
| `FIREBASE_AUTH_DOMAIN` | Firebase Auth Domain | `facconsult-19071.firebaseapp.com` |
| `FIREBASE_STORAGE_BUCKET` | Firebase Storage Bucket | `facconsult-19071.firebasestorage.app` |
| `FIREBASE_DATABASE_ID` | Firestore Database ID | `facconsult-firebase` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `FIREBASE_MEASUREMENT_ID` | Firebase Analytics Measurement ID | `null` |
| `ENABLE_DEBUG_LOGGING` | Enable debug logs | `false` |
| `ENABLE_ANALYTICS` | Enable Firebase Analytics | `false` |
| `ENABLE_CRASHLYTICS` | Enable Firebase Crashlytics | `false` |

---

## 💻 Using Environment Variables in Code

### Access Environment Name

```dart
import 'package:juciflut/firebase_options.dart';

// Get current environment
String env = DefaultFirebaseOptions.environment; // "dev", "staging", "prod"

// Check environment
if (DefaultFirebaseOptions.isDev) {
  print('Running in development');
}

if (DefaultFirebaseOptions.isProd) {
  print('Running in production');
}

// Check debug logging
if (DefaultFirebaseOptions.isDebugLoggingEnabled) {
  print('Debug logging enabled');
}
```

### Access Raw Environment Variables

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Get any environment variable
String? apiKey = dotenv.env['FIREBASE_API_KEY_WEB'];
String projectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? 'default-project';

// Check if variable exists
bool hasAnalytics = dotenv.env.containsKey('ENABLE_ANALYTICS');
```

### Use in Services

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'https://api.default.com';
  static int get timeout => int.parse(dotenv.env['API_TIMEOUT'] ?? '30000');
}
```

---

## 🔒 Security Best Practices

### ✅ DO:
- ✅ Keep `.env.example` updated for team reference
- ✅ Use different Firebase projects for dev/staging/prod
- ✅ Rotate API keys regularly
- ✅ Review `.gitignore` to ensure `.env` files are excluded
- ✅ Share `.env` files securely via password managers (1Password, LastPass)
- ✅ Document required environment variables

### ❌ DON'T:
- ❌ Commit `.env`, `.env.dev`, `.env.staging`, or `.env.prod` to Git
- ❌ Share `.env` files via email or public channels
- ❌ Include production keys in development environments
- ❌ Hardcode sensitive values in source code

---

## 🌍 Environment-Specific Configuration

### Development Environment (`.env.dev`)

**Purpose:** Local development and testing

**Configuration:**
```
ENVIRONMENT=dev
ENABLE_DEBUG_LOGGING=true
ENABLE_ANALYTICS=false
ENABLE_CRASHLYTICS=false
```

**Use Case:**
- Local development
- Feature testing
- Debug builds

---

### Staging Environment (`.env.staging`)

**Purpose:** Pre-production testing

**Configuration:**
```
ENVIRONMENT=staging
ENABLE_DEBUG_LOGGING=true
ENABLE_ANALYTICS=true
ENABLE_CRASHLYTICS=true
```

**Use Case:**
- QA testing
- User acceptance testing
- Integration testing with production-like data

**Recommendation:** Create a separate Firebase project for staging

---

### Production Environment (`.env.prod`)

**Purpose:** Live production environment

**Configuration:**
```
ENVIRONMENT=prod
ENABLE_DEBUG_LOGGING=false
ENABLE_ANALYTICS=true
ENABLE_CRASHLYTICS=true
```

**Use Case:**
- Production deployment
- Real user traffic
- Production data

**Critical:** Use production Firebase project only for production builds

---

## 🚢 Building for Production

### Web Production Build

```powershell
# 1. Switch to production environment
# Edit main.dart to use .env.prod OR copy .env.prod to .env

# 2. Build for production
flutter build web --release

# 3. Deploy
# Your build is in build/web/
```

### Build Script (PowerShell)

Create `build-prod.ps1`:

```powershell
# Build script for production
Write-Host "Building for PRODUCTION..." -ForegroundColor Yellow

# Backup current .env
Copy-Item .env .env.backup -Force

# Copy production environment
Copy-Item .env.prod .env -Force

# Build
flutter build web --release

# Restore backup
Copy-Item .env.backup .env -Force
Remove-Item .env.backup

Write-Host "Build complete! Output: build/web/" -ForegroundColor Green
```

Run with:
```powershell
.\build-prod.ps1
```

---

## 🧪 Testing Different Environments

### Test Development
```powershell
# Edit main.dart line 22
await dotenv.load(fileName: ".env.dev");

# Run
flutter run -d edge
```

### Test Staging
```powershell
# Edit main.dart line 22
await dotenv.load(fileName: ".env.staging");

# Run
flutter run -d edge
```

### Test Production (Locally)
```powershell
# Edit main.dart line 22
await dotenv.load(fileName: ".env.prod");

# Run
flutter run -d edge
```

**Check Console Output:**
```
🌍 Environment: prod
🔧 Debug logging: false
📊 Firestore database: facconsult-firebase
```

---

## 🐛 Troubleshooting

### Error: "Unable to load asset: .env"

**Cause:** .env file not found or not declared in `pubspec.yaml`

**Solution:**
1. Verify `.env` file exists in project root
2. Check `pubspec.yaml` has:
   ```yaml
   assets:
     - .env
     - .env.dev
     - .env.staging
     - .env.prod
   ```
3. Run `flutter pub get`
4. Hot restart the app

---

### Error: "Null check operator used on a null value"

**Cause:** Required environment variable is missing

**Solution:**
1. Check your `.env` file has all required variables
2. Compare with `.env.example`
3. Ensure no typos in variable names (case-sensitive)

---

### Environment Not Changing

**Cause:** App not restarted after changing `.env` file

**Solution:**
- Hot reload (`r`) doesn't reload `.env` files
- You MUST hot restart (`R`) or fully restart the app
- Or: Close app and run `flutter run` again

---

## 📝 Team Onboarding

### For New Team Members:

1. **Clone the repository**
   ```powershell
   git clone <repo-url>
   cd juciflut
   ```

2. **Copy `.env.example` to `.env`**
   ```powershell
   Copy-Item .env.example .env
   ```

3. **Get Firebase credentials from team lead**
   - Ask for `.env.dev` file contents
   - Update `.env` with actual values

4. **Install dependencies**
   ```powershell
   flutter pub get
   ```

5. **Run the app**
   ```powershell
   flutter run -d edge
   ```

---

## 📚 Additional Resources

- [flutter_dotenv Documentation](https://pub.dev/packages/flutter_dotenv)
- [Firebase Configuration](https://firebase.google.com/docs/flutter/setup)
- [Flutter Environment Variables](https://docs.flutter.dev/deployment/flavors)

---

## 🔗 Related Files

- [`pubspec.yaml`](cci:1://file:///c:/Users/User/Desktop/sC0l%20work/Flutter%20JuCi/juciflut/pubspec.yaml:0:0-0:0) - Dependencies
- [`lib/firebase_options.dart`](cci:1://file:///c:/Users/User/Desktop/sC0l%20work/Flutter%20JuCi/juciflut/lib/firebase_options.dart:0:0-0:0) - Firebase config using env vars
- [`lib/main.dart`](cci:1://file:///c:/Users/User/Desktop/sC0l%20work/Flutter%20JuCi/juciflut/lib/main.dart:0:0-0:0) - Environment loading
- [`.gitignore`](cci:1://file:///c:/Users/User/Desktop/sC0l%20work/Flutter%20JuCi/juciflut/.gitignore:0:0-0:0) - Git exclusions
- [`.env.example`](cci:1://file:///c:/Users/User/Desktop/sC0l%20work/Flutter%20JuCi/juciflut/.env.example:0:0-0:0) - Template

---

## ✅ Checklist

Before deploying to production:

- [ ] All required environment variables set in `.env.prod`
- [ ] Production Firebase project configured
- [ ] Debug logging disabled in production
- [ ] Analytics and Crashlytics enabled
- [ ] `.env` files excluded from Git
- [ ] Team members have access to environment files
- [ ] Build script tested
- [ ] Environment switching tested locally

---

**Need help?** Contact the development team or refer to the [main documentation](cci:1://file:///c:/Users/User/Desktop/sC0l%20work/Flutter%20JuCi/juciflut/README.md:0:0-0:0).
