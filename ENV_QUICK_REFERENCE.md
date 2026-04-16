# Environment Configuration - Quick Reference

## 🚀 Quick Commands

### Run Development
```powershell
# Default (uses .env pointing to dev)
flutter run -d edge
```

### Build for Production
```powershell
.\build-prod.ps1
```

### Build for Staging
```powershell
.\build-staging.ps1
```

### Install Dependencies
```powershell
flutter pub get
```

---

## 📁 Environment Files

| File | Purpose | Committed to Git? |
|------|---------|-------------------|
| `.env` | Default (currently dev) | ❌ No |
| `.env.dev` | Development | ❌ No |
| `.env.staging` | Staging/QA | ❌ No |
| `.env.prod` | Production | ❌ No |
| `.env.example` | Template for team | ✅ Yes |

---

## 🔧 Switch Environments

### Option 1: Edit main.dart (Line 22)

```dart
// Development
await dotenv.load(fileName: ".env.dev");

// Staging
await dotenv.load(fileName: ".env.staging");

// Production
await dotenv.load(fileName: ".env.prod");
```

### Option 2: Copy File

```powershell
# Use staging
Copy-Item .env.staging .env

# Use production
Copy-Item .env.prod .env
```

**Then restart the app (NOT hot reload!)**

---

## 📋 Required Environment Variables

```
ENVIRONMENT=dev
FIREBASE_API_KEY_WEB=...
FIREBASE_APP_ID_WEB=...
FIREBASE_MESSAGING_SENDER_ID=...
FIREBASE_PROJECT_ID=...
FIREBASE_AUTH_DOMAIN=...
FIREBASE_STORAGE_BUCKET=...
FIREBASE_DATABASE_ID=facconsult-firebase
```

---

## 💻 Access in Code

### Check Environment

```dart
import 'package:juciflut/firebase_options.dart';

// Get environment name
String env = DefaultFirebaseOptions.environment; // "dev", "staging", "prod"

// Check specific environment
if (DefaultFirebaseOptions.isDev) { }
if (DefaultFirebaseOptions.isStaging) { }
if (DefaultFirebaseOptions.isProd) { }

// Check debug logging
if (DefaultFirebaseOptions.isDebugLoggingEnabled) { }
```

### Get Environment Variable

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Get variable
String? value = dotenv.env['VARIABLE_NAME'];

// With default
String value = dotenv.env['VARIABLE_NAME'] ?? 'default';

// Check existence
bool exists = dotenv.env.containsKey('VARIABLE_NAME');
```

---

## 🐛 Common Issues

### Error: "Unable to load asset: .env"

**Fix:**
1. Verify `.env` exists in project root
2. Run `flutter pub get`
3. Hot restart app (`R`)

### Environment Not Changing

**Fix:**
- Hot reload (`r`) doesn't work
- Must hot restart (`R`) or fully restart app

### Null Check Error

**Fix:**
- Check all required variables are in `.env` file
- Compare with `.env.example`
- Check for typos (case-sensitive)

---

## ✅ Pre-Deployment Checklist

Before deploying to production:

- [ ] `.env.prod` has all required variables
- [ ] Debug logging disabled (`ENABLE_DEBUG_LOGGING=false`)
- [ ] Analytics enabled (`ENABLE_ANALYTICS=true`)
- [ ] Correct Firebase project ID
- [ ] Test build locally
- [ ] `.env` files not in Git

---

## 📞 Quick Help

- **Full Guide:** See `ENV_SETUP_GUIDE.md`
- **Template:** See `.env.example`
- **Build Scripts:** `build-prod.ps1`, `build-staging.ps1`

---

## 🔗 File Locations

All files in project root (`juciflut/`):

- `.env` - Default environment
- `.env.dev` - Development
- `.env.staging` - Staging
- `.env.prod` - Production
- `.env.example` - Template
- `build-prod.ps1` - Production build script
- `build-staging.ps1` - Staging build script
- `ENV_SETUP_GUIDE.md` - Full documentation
- `ENV_QUICK_REFERENCE.md` - This file
