# Booking System Implementation Guide

## ✅ Completed Components

### 1. Models
- ✅ **BookingModel** (`lib/models/booking_model.dart`)
  - Complete with Firestore serialization
  - Status enum and helper methods
  - Fields: id, schedule_id, faculty_id, student info, status, reason, timestamps

- ✅ **ScheduleModel** - Updated
  - Added `isBooked` field (boolean)
  - Updated `fromFirestore`, `toFirestore`, and `copyWith` methods

### 2. Services
- ✅ **BookingService** (`lib/services/booking_service.dart`)
  - `createBooking()` - Create new booking requests
  - `approveBooking()` - Approve and mark schedule as booked
  - `rejectBooking()` - Reject with optional reason
  - `cancelBooking()` - Cancel and unbook schedule if approved
  - `completeBooking()` - Mark as completed
  - `streamBookingsForFaculty()` - Real-time booking stream
  - `streamPendingBookings()` - Pending requests stream
  - `streamApprovedBookings()` - Approved bookings stream
  - `streamBookingsByStatus()` - Filter by status
  - `getBooking()`, `getBookingsForSchedule()`, `getBookingStats()`

### 3. Providers
- ✅ **BookingProvider** (`lib/providers/booking_provider.dart`)
  - State management for bookings
  - Filtering by status
  - CRUD operations wrapper
  - Error handling
  - Loading states

### 4. UI Components
- ✅ **BookingsPage** (`lib/views/pages/bookings_page.dart`)
  - Statistics cards (pending, approved, completed, total)
  - Filter tabs (all, pending, approved, completed, rejected, cancelled)
  - Booking cards with detailed info
  - Action buttons (approve, reject, cancel, complete)
  - Dialogs for confirmation with optional reasons
  - Empty states and error handling
  - Responsive design (mobile/desktop)

- ✅ **BookingRequestDialog** (`lib/widgets/booking_request_dialog.dart`)
  - Form for creating bookings on behalf of students
  - Fields: student email, name, department, reason
  - Validation and error handling

---

## 📋 Remaining Integration Steps

### Step 7: Update SchedulePage with Booking Indicators

Add the following to `lib/views/pages/schedule_page.dart`:

```dart
// At top of file, add import
import '../../widgets/booking_request_dialog.dart';

// In _buildScheduleTile method, add booking indicator:
Widget _buildScheduleTile(...) {
  return InkWell(
    // ... existing code ...
    child: Container(
      // ... existing decoration ...
      child: Row(
        children: [
          // Existing time + type indicator
          Container(...),
          
          // ADD THIS: Booking status indicator
          if (schedule.isBooked)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 12, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    'Booked',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(width: 12),
          Expanded(child: /* existing title/time column */),
          
          // Existing action buttons
          if (!isClass && !schedule.isBooked) ...[
            // ADD THIS: Book button for consultation slots
            if (schedule.type == 'consultation')
              IconButton(
                icon: const Icon(Icons.person_add, size: 18),
                color: Color(0xFF7C4DFF),
                onPressed: () => _showBookingDialog(context, prov, schedule),
                tooltip: 'Book Slot',
              ),
            // Existing edit button
            IconButton(...),
            // Existing delete button
            IconButton(...),
          ],
        ],
      ),
    ),
  );
}

// ADD THIS: Method to show booking dialog
void _showBookingDialog(BuildContext context, FacultyProvider prov, ScheduleModel schedule) {
  showDialog(
    context: context,
    builder: (ctx) => BookingRequestDialog(schedule: schedule),
  );
}
```

---

### Step 8: Update Navigation in DashboardShell

Update `lib/views/dashboard_shell.dart`:

```dart
// 1. Add BookingProvider to imports
import '../providers/booking_provider.dart';
import '../views/pages/bookings_page.dart';

// 2. Update main.dart to add BookingProvider
// In lib/main.dart, wrap app with MultiProvider:
return MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => FacultyProvider()),
    ChangeNotifierProvider(create: (_) => BookingProvider()),
  ],
  child: MaterialApp(...),
);

// 3. In DashboardShell, add Bookings to navigation
final List<Map<String, dynamic>> _pages = [
  {
    'title': 'Dashboard',
    'icon': Icons.dashboard,
    'page': const DashboardPage(),
  },
  {
    'title': 'Schedule',
    'icon': Icons.calendar_today,
    'page': const SchedulePage(),
  },
  {
    'title': 'Bookings',  // ADD THIS
    'icon': Icons.book_online,
    'page': const BookingsPage(),
  },
  {
    'title': 'Profile',
    'icon': Icons.person,
    'page': const ProfilePage(),
  },
];

// 4. In initState, initialize BookingProvider
@override
void initState() {
  super.initState();
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FacultyProvider>().initForUser(user);
      
      // ADD THIS: Initialize booking provider
      context.read<FacultyProvider>().addListener(() {
        final faculty = context.read<FacultyProvider>().faculty;
        if (faculty != null) {
          context.read<BookingProvider>().initForFaculty(faculty.id);
        }
      });
    });
  }
}
```

---

### Step 9: Update Firestore Security Rules

Add to `firestore.rules`:

```javascript
// =============================================================================
// BOOKINGS COLLECTION RULES
// =============================================================================

match /bookings/{bookingId} {
  // Helper to check if user owns the faculty_id
  function isFacultyBooking(facultyId) {
    return isAuthenticated() && 
           exists(/databases/$(database)/documents/faculty/$(facultyId)) &&
           get(/databases/$(database)/documents/faculty/$(facultyId)).data.email == getUserEmail();
  }
  
  // Allow read if booking belongs to user's faculty
  allow read: if isFacultyBooking(resource.data.faculty_id);
  
  // Allow create if user is creating booking for their faculty
  allow create: if isAuthenticated() &&
                   request.resource.data.keys().hasAll([
                     'schedule_id', 'faculty_id', 'student_email',
                     'student_name', 'student_department', 'status', 'reason'
                   ]) &&
                   request.resource.data.status == 'pending' &&
                   isFacultyBooking(request.resource.data.faculty_id);
  
  // Allow update if booking belongs to user
  // Cannot change faculty_id or schedule_id
  allow update: if isFacultyBooking(resource.data.faculty_id) &&
                   request.resource.data.faculty_id == resource.data.faculty_id &&
                   request.resource.data.schedule_id == resource.data.schedule_id;
  
  // Allow delete if booking belongs to user
  allow delete: if isFacultyBooking(resource.data.faculty_id);
}

// Update schedules collection to allow is_booked field
match /schedules/{scheduleId} {
  // ... existing rules ...
  
  // Update validation to include is_booked
  function isValidScheduleData(data) {
    return data.keys().hasAll(['faculty_id', 'day', 'time_start', 'time_end', 'type']) &&
           data.faculty_id is string && data.faculty_id.size() > 0 &&
           data.day is string && data.day in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'] &&
           data.time_start is string && data.time_start.size() > 0 &&
           data.time_end is string && data.time_end.size() > 0 &&
           data.type is string && data.type in ['consultation', 'class', 'meeting', 'office_hours'] &&
           (!('is_booked' in data) || data.is_booked is bool) &&  // ADD THIS
           (!('title' in data) || data.title is string) &&
           (!('location' in data) || data.location is string) &&
           (!('createdAt' in data) || data.createdAt is timestamp);
  }
}
```

---

## 🚀 Quick Start Commands

```powershell
# 1. Get dependencies (already done)
flutter pub get

# 2. Hot restart to apply changes
# Press R in terminal or use hot restart button

# 3. Test the booking system:
#    - Navigate to Schedule page
#    - Click "Book Slot" on consultation slot
#    - Fill in student details
#    - Submit booking
#    - Navigate to Bookings page
#    - See pending request
#    - Approve/reject booking
```

---

## 🧪 Testing Checklist

- [ ] Create a consultation slot in Schedule page
- [ ] Book slot using BookingRequestDialog
- [ ] Verify booking appears in Bookings page with "pending" status
- [ ] Approve booking - verify status changes to "approved"
- [ ] Verify schedule slot shows "Booked" indicator
- [ ] Test reject booking with reason
- [ ] Test cancel booking (for approved booking)
- [ ] Verify schedule.is_booked updates correctly
- [ ] Test filter tabs (all, pending, approved, etc.)
- [ ] Test mark booking as completed
- [ ] Test on mobile responsive layout
- [ ] Verify Firestore rules prevent unauthorized access

---

## 📊 Firestore Collections Structure

### bookings Collection
```
bookings/
  {bookingId}/
    schedule_id: string
    faculty_id: string
    student_email: string
    student_name: string
    student_department: string
    status: 'pending' | 'approved' | 'rejected' | 'completed' | 'cancelled'
    reason: string
    createdAt: timestamp
    updatedAt: timestamp
    rejection_reason?: string (optional)
    cancellation_reason?: string (optional)
    completed_at?: timestamp (optional)
```

### schedules Collection (Updated)
```
schedules/
  {scheduleId}/
    faculty_id: string
    day: string
    time_start: string
    time_end: string
    type: string
    title: string
    location: string
    is_booked: boolean  ← NEW FIELD
    createdAt: timestamp
```

---

## 📁 File Structure

```
lib/
├── models/
│   ├── booking_model.dart ✅
│   └── schedule_model.dart ✅ (updated)
├── services/
│   └── booking_service.dart ✅
├── providers/
│   ├── booking_provider.dart ✅
│   └── faculty_provider.dart
├── views/
│   └── pages/
│       ├── bookings_page.dart ✅
│       └── schedule_page.dart (needs update)
├── widgets/
│   └── booking_request_dialog.dart ✅
└── main.dart (needs MultiProvider update)
```

---

## 🔧 Environment Variables

No new environment variables needed. Uses existing:
- `FIREBASE_PROJECT_ID`
- `FIREBASE_DATABASE_ID`

---

## 🎯 Features Summary

### For Faculty:
✅ View all booking requests in one place  
✅ Filter by status (pending, approved, completed, etc.)  
✅ Approve/reject student requests  
✅ Book slots on behalf of students  
✅ Cancel bookings  
✅ Mark consultations as completed  
✅ See booking statistics  
✅ Visual indicators for booked slots  

### For Students (Future Enhancement):
- Student-facing portal to request bookings
- View booking status
- Receive notifications

---

## 🐛 Troubleshooting

### Bookings not showing?
- Check console for errors
- Verify `faculty.id` is correct
- Check Firestore rules allow read access
- Ensure BookingProvider is initialized

### Can't approve booking?
- Verify schedule document exists
- Check Firestore rules allow update
- Ensure is_booked field is allowed

### Schedule booking indicator not updating?
- Hot restart the app (R)
- Check schedule stream is active
- Verify is_booked field in Firestore

---

## 📞 Support

See also:
- `ENV_SETUP_GUIDE.md` - Environment configuration
- `FIRESTORE_RULES_GUIDE.md` - Security rules documentation
- `test-rules.md` - Testing security rules

---

**Booking system is 90% complete!** Just need to integrate the components as described in Steps 7-9. 🚀
