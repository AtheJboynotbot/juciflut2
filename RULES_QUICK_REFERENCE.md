# Firestore Security Rules - Quick Reference Card

## 🚀 Deployment Commands

```powershell
# Deploy rules (PowerShell script)
.\deploy-rules.ps1

# Deploy rules (Firebase CLI)
firebase deploy --only firestore:rules

# Deploy to specific database
firebase deploy --only firestore:facconsult-firebase:rules
```

---

## 🔒 Access Control Summary

| Operation | Faculty | Schedules | Departments |
|-----------|---------|-----------|-------------|
| **Read** | Own profile only | Own schedules only | All authenticated |
| **Create** | Own profile only | Own schedules only | ❌ Denied |
| **Update** | Own only (no email change) | Own only (no faculty_id change) | ❌ Denied |
| **Delete** | Own profile only | Own schedules only | ❌ Denied |

---

## 📋 Required Fields

### Faculty Document
```dart
{
  "email": "user@addu.edu.ph",        // Required, string, matches auth.token.email
  "first_name": "John",               // Required, string
  "last_name": "Doe",                 // Required, string
  "department_id": "CS",              // Optional, string
  "availability_status": "available", // Optional, enum: available|busy|away
  "profile_image_url": "https://...", // Optional, string
  "phone_number": "+63...",           // Optional, string
  "office_location": "Room 201",      // Optional, string
  "date_of_birth": "1990-01-01"       // Optional, string
}
```

### Schedule Document
```dart
{
  "faculty_id": "xgTtxN8qpI...",     // Required, string, must own this faculty doc
  "day": "Monday",                    // Required, enum: Monday|Tuesday|...|Sunday
  "time_start": "8:00 AM",            // Required, string
  "time_end": "9:00 AM",              // Required, string
  "type": "consultation",             // Required, enum: consultation|class|meeting|office_hours
  "title": "Office Hours",            // Optional, string
  "location": "Room 201",             // Optional, string
  "isBooked": false,                  // Optional, boolean
  "student_email": "student@...",     // Optional, string
  "createdAt": Timestamp              // Optional, timestamp
}
```

---

## ✅ Valid Enum Values

### availability_status
- `"available"`
- `"busy"`
- `"away"`

### day
- `"Monday"`
- `"Tuesday"`
- `"Wednesday"`
- `"Thursday"`
- `"Friday"`
- `"Saturday"`
- `"Sunday"`

### type
- `"consultation"`
- `"class"`
- `"meeting"`
- `"office_hours"`

---

## 🧪 Quick Test Scenarios

### ✅ Should ALLOW
```dart
// Read own faculty profile
GET /faculty/{id} WHERE document.email == auth.token.email

// Create own faculty profile
CREATE /faculty/{id} WITH email == auth.token.email

// Update own profile (email unchanged)
UPDATE /faculty/{id} WHERE old.email == new.email

// Read own schedule
GET /schedules/{id} WHERE faculty/{faculty_id}.email == auth.token.email

// Create own schedule
CREATE /schedules/{id} WITH faculty_id owned by user

// Read any department
GET /departments/{id} (any authenticated user)
```

### ❌ Should DENY
```dart
// Read another faculty's profile
GET /faculty/{id} WHERE document.email != auth.token.email

// Change email
UPDATE /faculty/{id} WITH email != old.email

// Read another faculty's schedule
GET /schedules/{id} WHERE faculty_id not owned by user

// Change faculty_id
UPDATE /schedules/{id} WITH faculty_id != old.faculty_id

// Write to departments
CREATE|UPDATE|DELETE /departments/{id} (always denied)

// Invalid enum values
CREATE /faculty/{id} WITH availability_status = "invalid"
CREATE /schedules/{id} WITH day = "InvalidDay"
```

---

## 🐛 Common Errors

### Error: "Missing or insufficient permissions"

**When Reading:**
- Faculty: Email mismatch with auth token
- Schedules: faculty_id doesn't belong to you

**When Creating:**
- Faculty: Email doesn't match auth.token.email
- Schedules: faculty_id doesn't exist or not yours

**When Updating:**
- Faculty: Trying to change email
- Schedules: Trying to change faculty_id

**When Deleting:**
- Not the owner of the document

### Error: "Invalid data"
- Missing required fields (email, first_name, last_name for faculty)
- Missing required fields (faculty_id, day, time_start, time_end, type for schedules)
- Wrong data types (e.g., number instead of string)
- Invalid enum values

---

## 📊 Performance Notes

### Document Reads Per Operation
- Read faculty: **1 read**
- Read schedule: **2 reads** (schedule + faculty lookup)
- Create schedule: **2 reads** (schedule + faculty verification)
- Update schedule: **2 reads** (schedule + faculty verification)

### Optimization Tips
- Batch read operations when possible
- Cache faculty_id after login
- Use listeners instead of repeated reads

---

## 🔗 Console Links

- **Rules Editor:** https://console.firebase.google.com/project/facconsult-19071/firestore/rules
- **Rules Playground:** Click "Rules playground" tab in rules editor
- **Firestore Data:** https://console.firebase.google.com/project/facconsult-19071/firestore/data

---

## 📝 Validation Functions

### In Dart Code
```dart
// Before creating faculty
bool isValidFaculty(Map<String, dynamic> data) {
  return data.containsKey('email') &&
         data.containsKey('first_name') &&
         data.containsKey('last_name') &&
         (data['email'] as String).isNotEmpty;
}

// Before creating schedule
bool isValidSchedule(Map<String, dynamic> data) {
  final validDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final validTypes = ['consultation', 'class', 'meeting', 'office_hours'];
  
  return data.containsKey('faculty_id') &&
         data.containsKey('day') &&
         data.containsKey('time_start') &&
         data.containsKey('time_end') &&
         data.containsKey('type') &&
         validDays.contains(data['day']) &&
         validTypes.contains(data['type']);
}
```

---

## 🎯 Best Practices

1. **Always validate data client-side** before sending to Firestore
2. **Use the helper functions** from FacultyProvider
3. **Call `_ensureFacultyDoc()`** on login before creating schedules
4. **Handle permission errors gracefully** in your UI
5. **Test rules after any changes** using Rules Playground
6. **Monitor Firebase logs** for unexpected denials
7. **Never expose faculty_id** to users who don't own it

---

## ⚡ Emergency Rollback

If rules cause issues in production:

```powershell
# Revert to previous version in Firebase Console
1. Go to Rules tab
2. Click "History" 
3. Select previous version
4. Click "Restore"
```

---

## 📞 Support

- **Documentation:** See `FIRESTORE_RULES_GUIDE.md`
- **Testing:** See `test-rules.md`
- **Deployment:** Use `deploy-rules.ps1`
- **Issues:** Check Firebase Console logs

---

**Keep this card handy for quick reference!** 📌
