# Schedule Conflict Detection - Implementation Guide

## ✅ Feature Complete!

I've implemented comprehensive schedule conflict detection to prevent double-booking in your JuCi Faculty Portal.

---

## 📦 What's Been Implemented

### **1. Time Parsing Utilities** ✅
**File:** `lib/utils/time_utils.dart`

Handles time string parsing and comparison:
- ✅ **`parseTimeToMinutes()`** - Converts "8:00 AM" → 480 minutes
- ✅ **`doTimeRangesOverlap()`** - Checks if two time ranges conflict
- ✅ **`formatMinutesToTime()`** - Converts minutes back to "8:00 AM"
- ✅ **`getDurationMinutes()`** - Calculate duration between times
- ✅ **`formatDuration()`** - Pretty format (e.g., "1 hour 30 minutes")

**Key Features:**
- Handles AM/PM format ("8:00 AM", "2:30 PM")
- Validates time ranges (start must be before end)
- Allows back-to-back slots (9-10 AM, then 10-11 AM) ✅
- Detects overlaps (9-11 AM conflicts with 10-12 PM) ✅

### **2. Validation Service** ✅
**File:** `lib/services/firestore_service.dart`

**New Method:** `validateSchedule()`
```dart
Future<ScheduleConflict?> validateSchedule({
  required String facultyId,
  required String day,
  required String timeStart,
  required String timeEnd,
  String? excludeScheduleId, // For updates
})
```

**How it works:**
1. Queries all schedules for faculty on the same day
2. Checks each for time overlap using `TimeUtils`
3. Returns `null` if valid, or `ScheduleConflict` object if conflict found
4. Excludes current schedule ID when editing (prevents self-conflict)

**New Class:** `ScheduleConflict`
```dart
class ScheduleConflict {
  final ScheduleModel conflictingSchedule;
  final String message;
}
```

### **3. Provider Integration** ✅
**File:** `lib/providers/faculty_provider.dart`

**New Method:** `validateSchedule()`
- Wrapper around FirestoreService validation
- Ensures faculty is loaded before validation
- Used by UI layer

### **4. UI Validation** ✅
**File:** `lib/views/pages/schedule_page.dart`

**Updated:** Add/Edit Schedule Dialog

**Workflow:**
1. User enters schedule details
2. Clicks "Save"
3. **VALIDATION HAPPENS FIRST** 🔍
4. If conflict found:
   - Dialog closes
   - Orange warning SnackBar appears
   - Shows conflict details
   - Schedule is NOT saved ❌
5. If no conflict:
   - Schedule saves successfully
   - Green success SnackBar
   - Dialog closes ✅

**Error Message Format:**
```
⚠️ Schedule Conflict Detected
Time slot overlaps with existing consultation: 
9:00 AM - 11:00 AM
Conflicting: Office Hours
```

---

## 🎯 Business Rules Implemented

### ✅ **Conflict Rules**
- **Same day + overlapping times** = ⚠️ CONFLICT
- **Different days + same times** = ✅ ALLOWED
- **Back-to-back slots** (9-10 AM, then 10-11 AM) = ✅ ALLOWED
- **Partial overlap** (9-11 AM with 10-12 PM) = ⚠️ CONFLICT

### ✅ **Validation Triggers**
- **Creating new schedule** - Validates against all existing
- **Editing schedule** - Validates against all except itself
- **Real-time** - Before saving to Firestore

---

## 🧪 Test Scenarios

### **Scenario 1: Exact Overlap**
```
Existing: Monday 9:00 AM - 11:00 AM (Consultation)
New:      Monday 9:00 AM - 11:00 AM (Class)
Result:   ⚠️ CONFLICT
```

### **Scenario 2: Partial Overlap**
```
Existing: Monday 9:00 AM - 11:00 AM
New:      Monday 10:00 AM - 12:00 PM
Result:   ⚠️ CONFLICT (overlaps 10-11 AM)
```

### **Scenario 3: Back-to-Back (ALLOWED)**
```
Existing: Monday 9:00 AM - 10:00 AM
New:      Monday 10:00 AM - 11:00 AM
Result:   ✅ NO CONFLICT (back-to-back is OK)
```

### **Scenario 4: Different Days**
```
Existing: Monday 9:00 AM - 11:00 AM
New:      Tuesday 9:00 AM - 11:00 AM
Result:   ✅ NO CONFLICT (different days)
```

### **Scenario 5: Completely Before**
```
Existing: Monday 10:00 AM - 12:00 PM
New:      Monday 8:00 AM - 9:00 AM
Result:   ✅ NO CONFLICT
```

### **Scenario 6: Editing Existing**
```
Existing: Monday 9:00 AM - 10:00 AM (ID: abc123)
Edit:     Monday 9:00 AM - 10:30 AM (ID: abc123)
Result:   ✅ NO CONFLICT (excludes itself)
```

---

## 🔧 Time Parsing Examples

### **Parse to Minutes**
```dart
TimeUtils.parseTimeToMinutes("8:00 AM")   // → 480
TimeUtils.parseTimeToMinutes("12:00 PM")  // → 720
TimeUtils.parseTimeToMinutes("2:30 PM")   // → 870
TimeUtils.parseTimeToMinutes("11:45 PM")  // → 1425
```

### **Check Overlap**
```dart
TimeUtils.doTimeRangesOverlap(
  start1: "9:00 AM",
  end1: "11:00 AM",
  start2: "10:00 AM",
  end2: "12:00 PM",
); // → true (overlap from 10-11 AM)

TimeUtils.doTimeRangesOverlap(
  start1: "9:00 AM",
  end1: "10:00 AM",
  start2: "10:00 AM",
  end2: "11:00 AM",
); // → false (back-to-back, no overlap)
```

### **Format Duration**
```dart
TimeUtils.getDurationMinutes("9:00 AM", "11:30 AM")  // → 150
TimeUtils.formatDuration(90)                          // → "1 hour 30 minutes"
TimeUtils.formatDuration(60)                          // → "1 hour"
TimeUtils.formatDuration(45)                          // → "45 minutes"
```

---

## 📁 Files Modified/Created

### **Created:**
- ✅ `lib/utils/time_utils.dart` - Time parsing utilities

### **Modified:**
- ✅ `lib/services/firestore_service.dart` - Added validation method + ScheduleConflict class
- ✅ `lib/providers/faculty_provider.dart` - Added validateSchedule wrapper
- ✅ `lib/views/pages/schedule_page.dart` - Added validation before save

---

## 🚀 Usage Example

### **In UI Code:**
```dart
// Validate before saving
final conflict = await provider.validateSchedule(
  day: 'Monday',
  timeStart: '9:00 AM',
  timeEnd: '11:00 AM',
  excludeScheduleId: editingId, // null for new, scheduleId for edit
);

if (conflict != null) {
  // Show error to user
  showErrorSnackBar(conflict.message);
  return; // Don't save
}

// No conflict - proceed with save
await provider.addSchedule(schedule);
```

---

## 🎨 UI/UX Features

### **Conflict Error Display:**
- 🟠 Orange warning color
- ⚠️ Warning icon in message
- **5-second duration** (longer than success messages)
- **Floating behavior** for better visibility
- **Multi-line content** showing:
  - Conflict detected header
  - Overlap details
  - Conflicting schedule info

### **User Experience:**
1. User fills schedule form
2. Clicks "Save"
3. **Instant validation** (< 1 second)
4. Clear error if conflict
5. User can adjust time and try again

---

## 🐛 Error Handling

### **Invalid Time Format**
```dart
try {
  TimeUtils.parseTimeToMinutes("25:00 AM"); // Invalid
} catch (e) {
  // FormatException: "Hours must be between 1 and 12"
}
```

### **Invalid Time Range**
```dart
try {
  TimeUtils.doTimeRangesOverlap(
    start1: "11:00 AM",
    end1: "9:00 AM", // end before start!
    start2: "10:00 AM",
    end2: "12:00 PM",
  );
} catch (e) {
  // FormatException: "Invalid range: start must be before end"
}
```

### **Faculty Not Loaded**
```dart
try {
  await provider.validateSchedule(...);
} catch (e) {
  // Exception: "Faculty not loaded"
}
```

---

## ✨ Advanced Features

### **Exclude Self on Edit**
When editing, pass the schedule ID to exclude:
```dart
await validateSchedule(
  day: 'Monday',
  timeStart: '9:00 AM',
  timeEnd: '10:30 AM',
  excludeScheduleId: currentSchedule.id, // Exclude self
);
```

### **Debug Logging**
All validation steps are logged:
```
🔍 [validateSchedule] Checking conflicts for Monday 9:00 AM-11:00 AM
🔍 [validateSchedule] Found 3 schedules on Monday
⚠️ [validateSchedule] CONFLICT DETECTED with schedule xyz123
```

Or if successful:
```
🔍 [validateSchedule] Checking conflicts for Tuesday 2:00 PM-3:00 PM
🔍 [validateSchedule] Found 2 schedules on Tuesday
✅ [validateSchedule] No conflicts found
```

---

## 🧪 Testing the Feature

### **Manual Test Steps:**

1. **Create first schedule:**
   - Day: Monday
   - Time: 9:00 AM - 11:00 AM
   - Type: Consultation
   - ✅ Should save successfully

2. **Try to create overlapping schedule:**
   - Day: Monday
   - Time: 10:00 AM - 12:00 PM
   - Type: Class
   - ⚠️ Should show conflict error
   - ❌ Should NOT save

3. **Create back-to-back schedule:**
   - Day: Monday
   - Time: 11:00 AM - 12:00 PM
   - Type: Meeting
   - ✅ Should save successfully (back-to-back OK)

4. **Create on different day:**
   - Day: Tuesday
   - Time: 9:00 AM - 11:00 AM
   - Type: Consultation
   - ✅ Should save successfully (different day)

5. **Edit existing schedule:**
   - Select Monday 9:00-11:00 AM schedule
   - Change to 9:00-11:30 AM
   - ✅ Should save (doesn't conflict with itself)

---

## 📊 Performance

- **Validation time:** < 1 second
- **Firestore query:** Single query per day
- **Indexed properly:** Uses `faculty_id` and `day` (compound index exists)
- **Minimal overhead:** Only validates on save, not on every keystroke

---

## 🔐 Security Notes

- Validation happens on **client side** before Firestore write
- **Server-side validation** should also be added via Firestore Rules
- Current implementation prevents accidental conflicts
- Malicious users could bypass client validation (add server rules!)

### **Recommended Firestore Rule:**
```javascript
// Add to firestore.rules
match /schedules/{scheduleId} {
  allow create: if request.auth != null &&
    // Add custom function to check for conflicts server-side
    !hasScheduleConflict(
      request.resource.data.faculty_id,
      request.resource.data.day,
      request.resource.data.time_start,
      request.resource.data.time_end
    );
}
```

---

## 📚 API Reference

### **TimeUtils.parseTimeToMinutes(String timeStr)**
- **Input:** "8:00 AM", "2:30 PM", etc.
- **Output:** Minutes since midnight (int)
- **Throws:** `FormatException` if invalid

### **TimeUtils.doTimeRangesOverlap({...})**
- **Params:** start1, end1, start2, end2
- **Output:** `true` if overlap, `false` if no overlap
- **Note:** Excludes exact boundaries (back-to-back allowed)

### **FirestoreService.validateSchedule({...})**
- **Returns:** `Future<ScheduleConflict?>` 
- **null** = no conflict
- **ScheduleConflict object** = conflict found

### **FacultyProvider.validateSchedule({...})**
- **Wrapper** around FirestoreService method
- **Throws:** Exception if faculty not loaded

---

## ✅ Summary

**You now have a complete conflict detection system!**

✅ Time parsing utilities  
✅ Overlap detection algorithm  
✅ Service layer validation  
✅ Provider integration  
✅ UI error handling  
✅ Clear user feedback  
✅ Support for editing  
✅ Back-to-back slots allowed  
✅ Comprehensive error messages  

**Try it out by creating overlapping schedules!** 🚀
