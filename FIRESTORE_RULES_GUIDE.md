# Firestore Security Rules - JuCi Faculty Portal

## Overview
Production-ready security rules for the JuCi faculty consultation scheduling app with email-based authentication and proper data validation.

---

## 🔒 Security Model

### Authentication
- All operations require Firebase Authentication
- User identity verified by `auth.token.email`

### Access Control
1. **Faculty Collection**: Users can only access their own profile (matched by email)
2. **Schedules Collection**: Users can only access schedules where `faculty_id` points to their faculty document
3. **Departments Collection**: Read-only for all authenticated users

---

## 📋 Rule Details

### Faculty Collection Rules

```javascript
// ✅ Allowed Operations:
- READ:   Own profile only (email matches auth email)
- CREATE: Own profile only (email = auth.token.email)
- UPDATE: Own profile only, cannot change email
- DELETE: Own profile only

// ❌ Prevented:
- Reading other faculty profiles
- Changing email field
- Creating profiles for other users
```

**Required Fields:**
- `email` (string, non-empty)
- `first_name` (string, non-empty)
- `last_name` (string, non-empty)

**Optional Fields:**
- `department_id` (string)
- `availability_status` (enum: 'available', 'busy', 'away')
- `profile_image_url` (string)
- `phone_number` (string)
- `office_location` (string)
- `date_of_birth` (string)

---

### Schedules Collection Rules

```javascript
// ✅ Allowed Operations:
- READ:   Schedules where faculty_id references user's faculty document
- CREATE: Schedules for user's faculty_id only
- UPDATE: Own schedules, cannot change faculty_id
- DELETE: Own schedules only

// ❌ Prevented:
- Reading other faculty's schedules
- Creating schedules for other faculty
- Changing faculty_id (schedule hijacking)
```

**Required Fields:**
- `faculty_id` (string, must match existing faculty document)
- `day` (enum: 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')
- `time_start` (string, format: "8:00 AM")
- `time_end` (string, format: "5:00 PM")
- `type` (enum: 'consultation', 'class', 'meeting', 'office_hours')

**Optional Fields:**
- `title` (string)
- `location` (string)
- `isBooked` (boolean)
- `student_email` (string)
- `createdAt` (timestamp)

---

### Departments Collection Rules

```javascript
// ✅ Allowed Operations:
- READ: All authenticated users

// ❌ Prevented:
- All write operations (admin-only via console)
```

---

## 🚀 Deployment

### Option 1: Firebase Console (Recommended)
1. Go to [Firebase Console](https://console.firebase.google.com/project/facconsult-19071/firestore/rules)
2. Copy contents of `firestore.rules`
3. Paste into the rules editor
4. Click **"Publish"**

### Option 2: Firebase CLI
```bash
# From project root
firebase deploy --only firestore:rules
```

### Option 3: Specify Database
```bash
# Deploy to specific database
firebase deploy --only firestore:facconsult-firebase:rules
```

---

## 🧪 Testing Rules

### Test 1: Faculty Profile Access
```javascript
// ✅ Should ALLOW: Reading own profile
// User: ajajudaya@addu.edu.ph
// Operation: READ /faculty/xgTtxN8qpITHCBq21OWv
// Condition: document.email == "ajajudaya@addu.edu.ph"

// ❌ Should DENY: Reading another faculty's profile
// User: ajajudaya@addu.edu.ph
// Operation: READ /faculty/differentFacultyId
// Reason: document.email != auth.token.email
```

### Test 2: Schedule Access
```javascript
// ✅ Should ALLOW: Reading own schedule
// User: ajajudaya@addu.edu.ph
// Operation: READ /schedules/NMFpDAGYy00QI7xYYg6k
// Condition: /faculty/xgTtxN8qpITHCBq21OWv.email == "ajajudaya@addu.edu.ph"

// ❌ Should DENY: Creating schedule for another faculty
// User: ajajudaya@addu.edu.ph
// Operation: CREATE /schedules/{id} with faculty_id: "differentFacultyId"
// Reason: faculty_id doesn't belong to user
```

### Test 3: Field Validation
```javascript
// ❌ Should DENY: Invalid availability_status
{
  "email": "test@addu.edu.ph",
  "first_name": "John",
  "last_name": "Doe",
  "availability_status": "invalid_status" // ❌ Not in enum
}

// ❌ Should DENY: Invalid day
{
  "faculty_id": "xgTtxN8qpITHCBq21OWv",
  "day": "InvalidDay", // ❌ Not in enum
  "time_start": "8:00 AM",
  "time_end": "9:00 AM",
  "type": "consultation"
}
```

---

## 🔍 Firebase Console Testing

### Navigate to Rules Playground:
1. Go to: https://console.firebase.google.com/project/facconsult-19071/firestore/rules
2. Click **"Rules playground"** tab

### Test Scenarios:

#### Scenario 1: Read Own Faculty Profile
```
Location: /faculty/xgTtxN8qpITHCBq21OWv
Operation: get
Authenticated: Yes
Email: ajajudaya@addu.edu.ph

Expected: ✅ ALLOW
```

#### Scenario 2: Create Schedule
```
Location: /schedules/newScheduleId
Operation: create
Authenticated: Yes
Email: ajajudaya@addu.edu.ph

Data:
{
  "faculty_id": "xgTtxN8qpITHCBq21OWv",
  "day": "Monday",
  "time_start": "8:00 AM",
  "time_end": "9:00 AM",
  "type": "consultation",
  "title": "Office Hours"
}

Expected: ✅ ALLOW
```

#### Scenario 3: Update Email (Should Fail)
```
Location: /faculty/xgTtxN8qpITHCBq21OWv
Operation: update
Authenticated: Yes
Email: ajajudaya@addu.edu.ph

Data:
{
  "email": "newemail@addu.edu.ph", // Trying to change email
  "first_name": "Updated"
}

Expected: ❌ DENY (cannot change email)
```

---

## 📊 Performance Considerations

### Document Reads Impact
The `isFacultySchedule()` function uses `get()` to verify ownership:
```javascript
get(/databases/$(database)/documents/faculty/$(facultyId))
```

**Impact:**
- Each schedule operation = +1 document read
- Affects billing (Firestore read quota)

**Optimization Options:**
1. **Use Cloud Functions**: Pre-compute ownership flags
2. **Duplicate Data**: Add `faculty_email` to schedule documents (denormalization)
3. **Accept Cost**: Small apps won't hit quota limits

**Current Approach:** Prioritizes security over optimization (acceptable for <10K schedules)

---

## 🛡️ Security Best Practices

### ✅ Implemented
- Email-based ownership verification
- Field-level validation
- Type checking for all fields
- Enum validation for status/type fields
- Prevention of faculty_id hijacking
- No expiration timestamps (rules never expire)

### ⚠️ Additional Recommendations
1. **Rate Limiting**: Add via Firebase App Check or Cloud Functions
2. **Content Validation**: Add regex for phone numbers, URLs
3. **Audit Logging**: Enable Firestore audit logs
4. **Monitoring**: Set up alerts for rule violations

---

## 🐛 Troubleshooting

### Error: "Missing or insufficient permissions"
**Cause:** User trying to access data they don't own

**Check:**
1. Is user authenticated? (`auth != null`)
2. Does faculty document email match `auth.token.email`?
3. Does schedule `faculty_id` point to user's faculty document?

### Error: "Invalid data"
**Cause:** Missing required fields or wrong data types

**Check:**
1. All required fields present?
2. Field types correct (string, bool, timestamp)?
3. Enum values valid?

### Error: "Document not found" during schedule creation
**Cause:** Faculty document doesn't exist yet

**Solution:**
1. Ensure `_ensureFacultyDoc()` runs before creating schedules
2. Check faculty document ID matches `faculty_id` in schedule

---

## 📝 Changelog

### v1.0.0 - Initial Release
- Email-based faculty authentication
- Schedule ownership via faculty_id lookup
- Field validation for all collections
- Department read-only access
- No expiration timestamps

---

## 🔗 Related Files
- **Rules File**: [`firestore.rules`](cci:1://file:///c:/Users/User/Desktop/sC0l%20work/Flutter%20JuCi/juciflut/firestore.rules:0:0-0:0)
- **Faculty Model**: [`lib/models/faculty_model.dart`](cci:1://file:///c:/Users/User/Desktop/sC0l%20work/Flutter%20JuCi/juciflut/lib/models/faculty_model.dart:0:0-0:0)
- **Schedule Model**: [`lib/models/schedule_model.dart`](cci:1://file:///c:/Users/User/Desktop/sC0l%20work/Flutter%20JuCi/juciflut/lib/models/schedule_model.dart:0:0-0:0)
- **Firestore Service**: [`lib/services/firestore_service.dart`](cci:1://file:///c:/Users/User/Desktop/sC0l%20work/Flutter%20JuCi/juciflut/lib/services/firestore_service.dart:0:0-0:0)

---

## 📞 Support
For issues or questions about these rules, contact the development team or refer to the [Firebase Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started).
