# Firestore Rules Testing Guide

## Manual Testing in Firebase Console

### Setup
1. Go to: https://console.firebase.google.com/project/facconsult-19071/firestore/rules
2. Click **"Rules playground"** tab
3. Ensure rules are published (click "Publish" if needed)

---

## Test Suite

### ✅ TEST 1: Read Own Faculty Profile (Should ALLOW)

```
Location: /faculty/xgTtxN8qpITHCBq21OWv
Operation: get
Authenticated: Yes
Auth UID: (any)
Custom Claims:
{
  "email": "ajajudaya@addu.edu.ph"
}
```

**Simulate Data (existing document):**
```json
{
  "email": "ajajudaya@addu.edu.ph",
  "first_name": "Albert John",
  "last_name": "Judaya",
  "department_id": "CS",
  "availability_status": "available"
}
```

**Expected Result:** ✅ **ALLOW**

---

### ❌ TEST 2: Read Another Faculty's Profile (Should DENY)

```
Location: /faculty/differentFacultyId
Operation: get
Authenticated: Yes
Auth UID: (any)
Custom Claims:
{
  "email": "ajajudaya@addu.edu.ph"
}
```

**Simulate Data (existing document):**
```json
{
  "email": "other@addu.edu.ph",
  "first_name": "Other",
  "last_name": "Faculty"
}
```

**Expected Result:** ❌ **DENY**  
**Reason:** `resource.data.email != auth.token.email`

---

### ✅ TEST 3: Create Own Faculty Profile (Should ALLOW)

```
Location: /faculty/newFacultyId
Operation: create
Authenticated: Yes
Auth UID: (any)
Custom Claims:
{
  "email": "newuser@addu.edu.ph"
}
```

**Request Data:**
```json
{
  "email": "newuser@addu.edu.ph",
  "first_name": "New",
  "last_name": "User",
  "availability_status": "available"
}
```

**Expected Result:** ✅ **ALLOW**

---

### ❌ TEST 4: Create Profile for Another User (Should DENY)

```
Location: /faculty/newFacultyId
Operation: create
Authenticated: Yes
Auth UID: (any)
Custom Claims:
{
  "email": "user1@addu.edu.ph"
}
```

**Request Data:**
```json
{
  "email": "user2@addu.edu.ph",
  "first_name": "User",
  "last_name": "Two"
}
```

**Expected Result:** ❌ **DENY**  
**Reason:** `request.resource.data.email != auth.token.email`

---

### ❌ TEST 5: Update Email (Should DENY)

```
Location: /faculty/xgTtxN8qpITHCBq21OWv
Operation: update
Authenticated: Yes
Auth UID: (any)
Custom Claims:
{
  "email": "ajajudaya@addu.edu.ph"
}
```

**Existing Data:**
```json
{
  "email": "ajajudaya@addu.edu.ph",
  "first_name": "Albert John",
  "last_name": "Judaya"
}
```

**Request Data (trying to update):**
```json
{
  "email": "newemail@addu.edu.ph",
  "first_name": "Albert John",
  "last_name": "Judaya"
}
```

**Expected Result:** ❌ **DENY**  
**Reason:** `request.resource.data.email != resource.data.email` (email cannot change)

---

### ✅ TEST 6: Update Own Profile (Should ALLOW)

```
Location: /faculty/xgTtxN8qpITHCBq21OWv
Operation: update
Authenticated: Yes
Auth UID: (any)
Custom Claims:
{
  "email": "ajajudaya@addu.edu.ph"
}
```

**Existing Data:**
```json
{
  "email": "ajajudaya@addu.edu.ph",
  "first_name": "Albert John",
  "last_name": "Judaya",
  "availability_status": "available"
}
```

**Request Data:**
```json
{
  "email": "ajajudaya@addu.edu.ph",
  "first_name": "Albert John",
  "last_name": "Judaya",
  "availability_status": "busy",
  "phone_number": "+63 123 456 7890"
}
```

**Expected Result:** ✅ **ALLOW**

---

### ❌ TEST 7: Create Faculty with Invalid Status (Should DENY)

```
Location: /faculty/newFacultyId
Operation: create
Authenticated: Yes
Auth UID: (any)
Custom Claims:
{
  "email": "user@addu.edu.ph"
}
```

**Request Data:**
```json
{
  "email": "user@addu.edu.ph",
  "first_name": "User",
  "last_name": "Name",
  "availability_status": "invalid_status"
}
```

**Expected Result:** ❌ **DENY**  
**Reason:** `availability_status` not in ['available', 'busy', 'away']

---

### ✅ TEST 8: Read Own Schedule (Should ALLOW)

```
Location: /schedules/NMFpDAGYy00QI7xYYg6k
Operation: get
Authenticated: Yes
Auth UID: (any)
Custom Claims:
{
  "email": "ajajudaya@addu.edu.ph"
}
```

**Simulate Schedule Data:**
```json
{
  "faculty_id": "xgTtxN8qpITHCBq21OWv",
  "day": "Monday",
  "time_start": "8:00 AM",
  "time_end": "9:00 AM",
  "type": "consultation",
  "title": "Office Hours"
}
```

**Simulate Faculty Data at `/faculty/xgTtxN8qpITHCBq21OWv`:**
```json
{
  "email": "ajajudaya@addu.edu.ph",
  "first_name": "Albert John",
  "last_name": "Judaya"
}
```

**Expected Result:** ✅ **ALLOW**  
**Note:** Rules playground will verify `faculty_id` points to document with matching email

---

### ❌ TEST 9: Read Another Faculty's Schedule (Should DENY)

```
Location: /schedules/someScheduleId
Operation: get
Authenticated: Yes
Auth UID: (any)
Custom Claims:
{
  "email": "user1@addu.edu.ph"
}
```

**Simulate Schedule Data:**
```json
{
  "faculty_id": "differentFacultyId",
  "day": "Monday",
  "time_start": "8:00 AM",
  "time_end": "9:00 AM",
  "type": "consultation"
}
```

**Simulate Faculty Data at `/faculty/differentFacultyId`:**
```json
{
  "email": "user2@addu.edu.ph",
  "first_name": "Other",
  "last_name": "User"
}
```

**Expected Result:** ❌ **DENY**  
**Reason:** Faculty document email doesn't match auth email

---

### ✅ TEST 10: Create Own Schedule (Should ALLOW)

```
Location: /schedules/newScheduleId
Operation: create
Authenticated: Yes
Auth UID: (any)
Custom Claims:
{
  "email": "ajajudaya@addu.edu.ph"
}
```

**Request Data:**
```json
{
  "faculty_id": "xgTtxN8qpITHCBq21OWv",
  "day": "Tuesday",
  "time_start": "10:00 AM",
  "time_end": "11:00 AM",
  "type": "consultation",
  "title": "Student Consultation",
  "location": "Room 201"
}
```

**Simulate Faculty Data at `/faculty/xgTtxN8qpITHCBq21OWv`:**
```json
{
  "email": "ajajudaya@addu.edu.ph",
  "first_name": "Albert John",
  "last_name": "Judaya"
}
```

**Expected Result:** ✅ **ALLOW**

---

### ❌ TEST 11: Create Schedule with Invalid Day (Should DENY)

```
Location: /schedules/newScheduleId
Operation: create
Authenticated: Yes
Auth UID: (any)
Custom Claims:
{
  "email": "ajajudaya@addu.edu.ph"
}
```

**Request Data:**
```json
{
  "faculty_id": "xgTtxN8qpITHCBq21OWv",
  "day": "InvalidDay",
  "time_start": "10:00 AM",
  "time_end": "11:00 AM",
  "type": "consultation"
}
```

**Expected Result:** ❌ **DENY**  
**Reason:** `day` not in ['Monday', 'Tuesday', ..., 'Sunday']

---

### ❌ TEST 12: Create Schedule for Another Faculty (Should DENY)

```
Location: /schedules/newScheduleId
Operation: create
Authenticated: Yes
Auth UID: (any)
Custom Claims:
{
  "email": "user1@addu.edu.ph"
}
```

**Request Data:**
```json
{
  "faculty_id": "differentFacultyId",
  "day": "Monday",
  "time_start": "10:00 AM",
  "time_end": "11:00 AM",
  "type": "consultation"
}
```

**Simulate Faculty Data at `/faculty/differentFacultyId`:**
```json
{
  "email": "user2@addu.edu.ph",
  "first_name": "Other",
  "last_name": "User"
}
```

**Expected Result:** ❌ **DENY**  
**Reason:** `faculty_id` doesn't belong to authenticated user

---

### ❌ TEST 13: Change Schedule's faculty_id (Should DENY)

```
Location: /schedules/existingScheduleId
Operation: update
Authenticated: Yes
Auth UID: (any)
Custom Claims:
{
  "email": "ajajudaya@addu.edu.ph"
}
```

**Existing Data:**
```json
{
  "faculty_id": "xgTtxN8qpITHCBq21OWv",
  "day": "Monday",
  "time_start": "8:00 AM",
  "time_end": "9:00 AM",
  "type": "consultation"
}
```

**Request Data:**
```json
{
  "faculty_id": "differentFacultyId",
  "day": "Monday",
  "time_start": "8:00 AM",
  "time_end": "9:00 AM",
  "type": "consultation"
}
```

**Expected Result:** ❌ **DENY**  
**Reason:** `request.resource.data.faculty_id != resource.data.faculty_id` (cannot change faculty_id)

---

### ✅ TEST 14: Read Departments (Should ALLOW)

```
Location: /departments/CS
Operation: get
Authenticated: Yes
Auth UID: (any)
Custom Claims:
{
  "email": "anyuser@addu.edu.ph"
}
```

**Simulate Data:**
```json
{
  "name": "Computer Science",
  "code": "CS"
}
```

**Expected Result:** ✅ **ALLOW**  
**Reason:** All authenticated users can read departments

---

### ❌ TEST 15: Write to Departments (Should DENY)

```
Location: /departments/newDept
Operation: create
Authenticated: Yes
Auth UID: (any)
Custom Claims:
{
  "email": "anyuser@addu.edu.ph"
}
```

**Request Data:**
```json
{
  "name": "New Department",
  "code": "ND"
}
```

**Expected Result:** ❌ **DENY**  
**Reason:** Write operations on departments collection are always denied

---

## Quick Test Checklist

Run through this checklist after deploying rules:

- [ ] ✅ TEST 1: Read own faculty profile
- [ ] ❌ TEST 2: Read another faculty's profile
- [ ] ✅ TEST 3: Create own faculty profile
- [ ] ❌ TEST 4: Create profile for another user
- [ ] ❌ TEST 5: Update email field
- [ ] ✅ TEST 6: Update own profile
- [ ] ❌ TEST 7: Create faculty with invalid status
- [ ] ✅ TEST 8: Read own schedule
- [ ] ❌ TEST 9: Read another faculty's schedule
- [ ] ✅ TEST 10: Create own schedule
- [ ] ❌ TEST 11: Create schedule with invalid day
- [ ] ❌ TEST 12: Create schedule for another faculty
- [ ] ❌ TEST 13: Change schedule's faculty_id
- [ ] ✅ TEST 14: Read departments
- [ ] ❌ TEST 15: Write to departments

---

## Notes

- Use custom claims to set `email` in Rules Playground
- Simulate existing documents for read/update/delete operations
- Verify `get()` calls work by setting up referenced documents
- All tests should pass before deploying to production

---

## Automated Testing (Future Enhancement)

For automated testing, consider using:
- **Firebase Emulator Suite**: Test rules locally
- **@firebase/rules-unit-testing**: Write Jest tests

Example:
```bash
firebase emulators:start --only firestore
npm test
```
