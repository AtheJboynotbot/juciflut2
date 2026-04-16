# Firebase Analytics & Crashlytics - Quick Start

## 🚀 How to Add Event Tracking

### **Step 1: Import the service**

```dart
import '../../services/analytics_service.dart';
```

---

### **Step 2: Track user actions**

#### **Login (in web_login_screen.dart)**

```dart
// After successful Google Sign-In
await AnalyticsService.logLoginSuccess(
  method: 'google',
  email: userCredential.user?.email,
);

// Set user ID and properties
await AnalyticsService.setUserId(faculty.id);
await AnalyticsService.setUserProperties(
  department: faculty.departmentId,
  role: 'faculty',
  email: faculty.email,
);
```

---

#### **Create Schedule (in dashboard_page.dart or schedule_page.dart)**

```dart
// After successfully creating schedule
await AnalyticsService.logScheduleCreated(
  scheduleType: selectedType, // 'consultation', 'class', 'meeting'
  day: selectedDay,           // 'Monday', 'Tuesday', etc.
  duration: '$startStr - $endStr',
);
```

---

#### **Update Schedule**

```dart
// After successfully updating schedule
await AnalyticsService.logScheduleUpdated(
  scheduleType: schedule.type,
  day: schedule.day,
);
```

---

#### **Delete Schedule**

```dart
// Before or after deleting schedule
await AnalyticsService.logScheduleDeleted(
  scheduleType: schedule.type,
  day: schedule.day,
);
```

---

#### **Update Profile (in profile_page.dart)**

```dart
// Track which fields were updated
final updatedFields = <String>[];
if (phoneChanged) updatedFields.add('phone');
if (officeChanged) updatedFields.add('office');
if (dobChanged) updatedFields.add('dateOfBirth');

await AnalyticsService.logProfileUpdated(
  fieldsUpdated: updatedFields,
);
```

---

#### **Upload Profile Image**

```dart
// After successful image upload
await AnalyticsService.logProfileImageUploaded(
  fileSize: imageBytes.length,
);
```

---

#### **Request Booking**

```dart
// When student requests a booking
await AnalyticsService.logBookingRequested(
  scheduleType: 'consultation',
  day: 'Monday',
  timeSlot: '9:00 AM - 10:00 AM',
);
```

---

#### **Schedule Conflict**

```dart
// When conflict is detected
if (conflict != null) {
  await AnalyticsService.logScheduleConflict(
    day: selectedDay,
    timeRange: '$startTime - $endTime',
  );
}
```

---

### **Step 3: Add error tracking**

```dart
try {
  await riskyOperation();
} catch (e, stackTrace) {
  // Record error to Crashlytics
  await AnalyticsService.recordError(
    e,
    stackTrace,
    reason: 'What operation failed',
    fatal: false, // true if app will crash
  );
  
  // Show error to user
  showErrorDialog(context, e.toString());
}
```

---

### **Step 4: Add breadcrumbs (optional)**

```dart
// Before critical operations
AnalyticsService.log('Starting schedule creation');

try {
  await createSchedule();
  AnalyticsService.log('Schedule created successfully');
} catch (e) {
  AnalyticsService.log('Schedule creation failed');
  throw e;
}
```

---

## 📋 Files to Update

1. **web_login_screen.dart** - Login tracking + user properties
2. **dashboard_page.dart** - Schedule CRUD tracking
3. **schedule_page.dart** - Schedule CRUD tracking  
4. **profile_page.dart** - Profile update tracking
5. **All error handlers** - Add AnalyticsService.recordError()

---

## 🧪 Testing

### **Enable Debug View:**

```bash
# Android
adb shell setprop debug.firebase.analytics.app com.example.juciflut

# iOS
Add -FIRDebugEnabled to scheme arguments
```

### **Test Crash:**

```dart
// Add button in dev mode only
if (kDebugMode) {
  FloatingActionButton(
    onPressed: () {
      AnalyticsService.testCrash();
    },
    child: const Icon(Icons.bug_report),
  );
}
```

### **View Events:**

1. Open Firebase Console
2. Go to Analytics → Events
3. Enable Debug View
4. Trigger events in app
5. See them appear in real-time

---

## 🎯 Priority Events to Add First

1. ✅ Login success (web_login_screen.dart)
2. ✅ Schedule created (dashboard_page.dart)
3. ✅ Schedule deleted (dashboard_page.dart)
4. ✅ Profile updated (profile_page.dart)
5. ✅ Error tracking (all try-catch blocks)

---

## 📚 Full Documentation

See `ANALYTICS_COMPLETE.md` for comprehensive documentation and all available methods.

---

## ⚡ Quick Reference

```dart
// Import
import '../../services/analytics_service.dart';

// Track event
await AnalyticsService.logScheduleCreated(
  scheduleType: 'consultation',
  day: 'Monday',
  duration: '1 hour',
);

// Record error
await AnalyticsService.recordError(e, stackTrace);

// Set user data
await AnalyticsService.setUserId(userId);
await AnalyticsService.setUserProperties(department: 'CS');

// Log breadcrumb
AnalyticsService.log('User clicked save button');
```
