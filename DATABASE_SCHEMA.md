# Firestore Database Schema

**Last Updated:** April 9, 2026  
**Status:** ✅ App now matches database schema exactly

---

## Collections

### 1. `faculty` Collection
Stores faculty/user profile data.

**Fields:**
- `email` (string) - Faculty email address (unique identifier)
- `first_name` (string) - First name
- `last_name` (string) - Last name
- `department_id` (string) - Reference to department document ID
- `availability_status` (string) - "available" | "busy" | "away"
- `profile_image_url` (string) - URL to profile picture in Firebase Storage
- `phone_number` (string) - Contact phone number
- `office_location` (string) - Office room/building
- `date_of_birth` (timestamp | null) - Date of birth

**Example Document:**
```json
{
  "email": "mcgabayan@addu.edu.ph",
  "first_name": "Maria Corazon",
  "last_name": "Gabayan",
  "department_id": "ZzsLnZqOtZKEhg9KAIX",
  "availability_status": "busy",
  "profile_image_url": "",
  "phone_number": "",
  "office_location": "",
  "date_of_birth": null
}
```

---

### 2. `schedules` Collection
Stores consultation/class schedule slots for faculty.

**Fields:**
- `faculty_id` (string) - Reference to faculty document ID ⚠️ **Uses underscore**
- `day` (string) - Day of week: "Monday", "Tuesday", etc.
- `time_start` (string) - Start time in AM/PM format: "10:00 AM"
- `time_end` (string) - End time in AM/PM format: "12:00 PM"
- `type` (string) - "consultation" | "class" | "meeting"
- `title` (string) - Optional title/description
- `location` (string) - Room/building location
- `createdAt` (timestamp) - Server timestamp

**Example Document:**
```json
{
  "faculty_id": "pQyJXO3XFCE64Wam5yzJ",
  "day": "Tuesday",
  "time_start": "10:00 AM",
  "time_end": "12:00 PM",
  "type": "consultation",
  "title": "",
  "location": "",
  "createdAt": "April 7, 2026 at 3:25:57 PM UTC+8"
}
```

---

### 3. `departments` Collection
Stores department reference data.

**Fields:**
- `name` (string) - Department name

**Example Document:**
```json
{
  "name": "Civil Engineering"
}
```

---

### 4. `users` Collection ⚠️ **DEPRECATED**
Old authentication collection. No longer used by the app.  
Can be safely deleted or kept for backward compatibility.

---

## Critical Field Naming

### ⚠️ **IMPORTANT: Snake Case vs Camel Case**

The app now correctly uses **snake_case** for all Firestore fields to match your database:

| Field in App (Dart) | Field in Firestore | ✅ Match |
|---------------------|-------------------|---------|
| `facultyId` | `faculty_id` | ✅ |
| `timeStart` | `time_start` | ✅ |
| `timeEnd` | `time_end` | ✅ |
| `firstName` | `first_name` | ✅ |
| `lastName` | `last_name` | ✅ |
| `departmentId` | `department_id` | ✅ |
| `profileImageUrl` | `profile_image_url` | ✅ |

---

## Firestore Indexes Required

For the queries to work efficiently, ensure these indexes exist:

### schedules Collection
1. **faculty_id + day + time_start** (Ascending)
2. **faculty_id + type** (Ascending)

Check: Firebase Console → Firestore → Indexes

---

## Security Rules

Current rules expire **May 1, 2026**. Update before then!

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## Changes Made Today

✅ Fixed `faculty_id` field naming (was `facultyId`)  
✅ Fixed all Firestore queries to use `faculty_id`  
✅ Added profile fields: `phone_number`, `office_location`, `date_of_birth`  
✅ Replaced `image_picker` with `file_picker` for web compatibility  
✅ Added debug logging to track data flow  

**Result:** App now saves and loads data correctly from Firestore! 🎉
