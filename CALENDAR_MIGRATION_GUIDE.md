# 🗓️ Calendar Migration Guide - Day-Based → Date-Specific Scheduling

## ✅ Phase 1: Database Schema Updates - **COMPLETE!**

### **ScheduleModel Updated**

✅ **New Fields Added:**
```dart
final String? date;                 // '2026-04-20' (YYYY-MM-DD)
final String status;                // 'active' | 'cancelled' | 'rescheduled'
final String? cancellationReason;   // Why it was cancelled
final DateTime? cancelledAt;        // When it was cancelled
final int maxBookings;              // Maximum bookings allowed
final int currentBookings;          // Current number of bookings
```

✅ **Legacy Field (Backwards Compatible):**
```dart
final String? day;  // 'Monday', 'Tuesday', etc. (now optional)
```

✅ **Helper Methods:**
```dart
bool get isCancelled        // Check if cancelled
bool get isActive           // Check if active
bool get isFullyBooked      // Check if all slots taken
int get availableSlots      // Remaining slots
DateTime? get dateTime      // Parse date string to DateTime
String get displayDate      // Get weekday name
String? get formattedDate   // "April 20, 2026"
```

---

## 📦 Phase 2: Package Installation

### **Add table_calendar Package**

✅ **Added to pubspec.yaml:**
```yaml
dependencies:
  table_calendar: ^3.0.9
```

**Run:**
```bash
flutter pub get
```

---

## 🎨 Phase 3: UI Components to Create

### **1. Main Calendar Widget** (`lib/widgets/schedule_calendar_widget.dart`)

**Purpose:** Primary interface - month grid view with schedule indicators

**Features:**
- Month navigation (previous/next)
- Visual indicators for schedules (dots, colors)
- Click date to view/add schedules
- Color coding:
  - Green border: Active schedules
  - Red border: Cancelled schedules
  - Purple: Fully booked
  - Orange: Partially booked
- Booking dots: •, ••, ••• (1, 2, 3+ bookings)

**Usage:**
```dart
ScheduleCalendarWidget(
  facultyId: faculty.id,
  schedules: allSchedules,
  onDateSelected: (date) => _showDayDetail(date),
  onDateLongPress: (date) => _quickAddSchedule(date),
)
```

---

### **2. Day Detail Sheet** (`lib/widgets/day_detail_sheet.dart`)

**Purpose:** Shows all schedules for a specific date

**Features:**
- List all schedules for the day
- Show booking status for each
- Quick actions: Edit, Cancel, View Bookings
- Add another schedule button

**Usage:**
```dart
showModalBottomSheet(
  context: context,
  builder: (context) => DayDetailSheet(
    date: selectedDate,
    schedules: schedulesForDay,
    onEdit: (schedule) => _editSchedule(schedule),
    onCancel: (schedule) => _cancelSchedule(schedule),
  ),
);
```

---

### **3. Quick Add Dialog** (`lib/widgets/quick_add_schedule_dialog.dart`)

**Purpose:** Fast schedule creation for a single date

**Features:**
- Time pickers (start/end)
- Type dropdown (consultation, class, meeting)
- Title, location input
- Max bookings input
- Link to advanced builder

**Usage:**
```dart
await showDialog(
  context: context,
  builder: (context) => QuickAddScheduleDialog(
    date: selectedDate,
    onSave: (schedule) => _createSchedule(schedule),
  ),
);
```

---

### **4. Advanced Schedule Builder** (`lib/widgets/advanced_schedule_builder.dart`)

**Purpose:** Create schedules for multiple dates

**Features:**
- Multi-date selection calendar
- Quick patterns: "Every Monday from Apr 1 to Jun 30"
- Same time/details for all selected dates
- Batch creation

**Usage:**
```dart
await showDialog(
  context: context,
  builder: (context) => AdvancedScheduleBuilder(
    onSave: (List<ScheduleModel> schedules) => _batchCreate(schedules),
  ),
);
```

---

### **5. Cancel Schedule Dialog** (`lib/widgets/cancel_schedule_dialog.dart`)

**Purpose:** Cancel schedules with notification to students

**Features:**
- List affected schedules
- Show number of bookings
- Cancellation reason input
- Email notification checkbox
- Batch cancellation

**Usage:**
```dart
await showDialog(
  context: context,
  builder: (context) => CancelScheduleDialog(
    schedules: schedulesToCancel,
    onConfirm: (reason) => _processCancel(reason),
  ),
);
```

---

## 🔄 Phase 4: Service Layer Updates

### **Update FirestoreService** (`lib/services/firestore_service.dart`)

**New Methods Needed:**

```dart
// Query schedules by date range
Stream<List<ScheduleModel>> schedulesInDateRange({
  required String facultyId,
  required DateTime startDate,
  required DateTime endDate,
}) {
  return _firestore
      .collection('schedules')
      .where('faculty_id', isEqualTo: facultyId)
      .where('date', isGreaterThanOrEqualTo: _formatDate(startDate))
      .where('date', isLessThanOrEqualTo: _formatDate(endDate))
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ScheduleModel.fromFirestore(doc))
          .toList());
}

// Get schedules for a specific date
Future<List<ScheduleModel>> schedulesForDate({
  required String facultyId,
  required DateTime date,
}) async {
  final dateStr = _formatDate(date);
  final snapshot = await _firestore
      .collection('schedules')
      .where('faculty_id', isEqualTo: facultyId)
      .where('date', isEqualTo: dateStr)
      .get();
  
  return snapshot.docs
      .map((doc) => ScheduleModel.fromFirestore(doc))
      .toList();
}

// Cancel schedule
Future<void> cancelSchedule({
  required String scheduleId,
  required String reason,
}) async {
  await _firestore.collection('schedules').doc(scheduleId).update({
    'status': 'cancelled',
    'cancellation_reason': reason,
    'cancelled_at': Timestamp.now(),
  });
  
  // TODO: Trigger notifications to affected students
}

// Batch create schedules
Future<void> batchCreateSchedules(List<ScheduleModel> schedules) async {
  final batch = _firestore.batch();
  
  for (final schedule in schedules) {
    final docRef = _firestore.collection('schedules').doc();
    batch.set(docRef, schedule.toFirestore());
  }
  
  await batch.commit();
}

// Helper to format date as YYYY-MM-DD
String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
```

---

## 📱 Phase 5: Update Schedule Page

### **Replace schedule_page.dart**

**Current:** List view grouped by day of week  
**New:** Calendar-first interface

**Key Changes:**

```dart
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // Map to store schedules by date
  Map<DateTime, List<ScheduleModel>> _schedulesByDate = {};

  @override
  Widget build(BuildContext context) {
    return Consumer<FacultyProvider>(
      builder: (context, prov, _) {
        _loadSchedulesForMonth(prov);
        
        return Column(
          children: [
            // Header with view toggles
            _buildHeader(),
            
            // Main calendar
            Expanded(
              child: _calendarFormat == CalendarFormat.month
                  ? _buildCalendarView(prov)
                  : _buildListView(prov),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalendarView(FacultyProvider prov) {
    return ScheduleCalendarWidget(
      facultyId: prov.faculty!.id,
      schedules: prov.allSchedules,
      focusedDay: _focusedDay,
      onDateSelected: (date) => _showDayDetail(date),
      onMonthChanged: (date) => setState(() => _focusedDay = date),
    );
  }
  
  void _showDayDetail(DateTime date) {
    final schedules = _getSchedulesForDate(date);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DayDetailSheet(
        date: date,
        schedules: schedules,
        onAdd: () => _quickAddSchedule(date),
        onEdit: (schedule) => _editSchedule(schedule),
        onCancel: (schedule) => _cancelSchedule(schedule),
      ),
    );
  }
}
```

---

## 🔔 Phase 6: Notification System

### **Create NotificationService** (`lib/services/notification_service.dart`)

**Purpose:** Send emails when schedules are cancelled

**Implementation Options:**

#### **Option A: Cloud Functions (Recommended)**
```javascript
// Firebase Cloud Function
exports.sendCancellationEmail = functions.firestore
  .document('schedules/{scheduleId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // Check if status changed to cancelled
    if (before.status !== 'cancelled' && after.status === 'cancelled') {
      // Get affected bookings
      const bookingsSnapshot = await admin.firestore()
        .collection('bookings')
        .where('schedule_id', '==', context.params.scheduleId)
        .get();
      
      // Send emails to all students
      const promises = bookingsSnapshot.docs.map(booking => {
        return sendEmail({
          to: booking.data().student_email,
          subject: 'Schedule Cancelled',
          body: `Your booking for ${after.date} at ${after.time_start} has been cancelled.\n\nReason: ${after.cancellation_reason}`,
        });
      });
      
      await Promise.all(promises);
    }
  });
```

#### **Option B: Flutter + Email API**
```dart
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class NotificationService {
  static Future<void> sendCancellationEmail({
    required String scheduleId,
    required String date,
    required String timeRange,
    required String reason,
  }) async {
    // Get affected bookings
    final bookings = await _getBookingsForSchedule(scheduleId);
    
    for (final booking in bookings) {
      final message = Message()
        ..from = Address('noreply@juci.edu', 'JuCi Faculty Portal')
        ..recipients.add(booking.studentEmail)
        ..subject = 'Schedule Cancellation Notice'
        ..html = '''
          <h2>Schedule Cancelled</h2>
          <p>Your booking has been cancelled:</p>
          <ul>
            <li><strong>Date:</strong> $date</li>
            <li><strong>Time:</strong> $timeRange</li>
            <li><strong>Reason:</strong> $reason</li>
          </ul>
          <p>Please book another slot if needed.</p>
        ''';
      
      try {
        final smtpServer = gmail('your-email@gmail.com', 'app-password');
        await send(message, smtpServer);
        
        // Mark notification as sent
        await _markNotificationSent(booking.id);
      } catch (e) {
        AppLogger.error('Failed to send email', e);
      }
    }
  }
}
```

---

## 🔄 Phase 7: Data Migration

### **Migrate Existing Schedules from Day → Date**

**Migration Script:**

```dart
Future<void> migrateSchedulesToDateBased() async {
  // Get all schedules
  final snapshot = await FirebaseFirestore.instance
      .collection('schedules')
      .where('day', whereIn: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'])
      .get();
  
  final batch = FirebaseFirestore.instance.batch();
  
  for (final doc in snapshot.docs) {
    final data = doc.data();
    final day = data['day'] as String;
    
    // Generate dates for next 3 months
    final dates = _generateDatesForDay(day, months: 3);
    
    // Create new schedule for each date
    for (final date in dates) {
      final newDocRef = FirebaseFirestore.instance.collection('schedules').doc();
      batch.set(newDocRef, {
        ...data,
        'date': date,
        'status': 'active',
        'day': null, // Remove legacy field
      });
    }
    
    // Delete old day-based schedule
    batch.delete(doc.reference);
  }
  
  await batch.commit();
  AppLogger.info('Migration complete: ${snapshot.docs.length} schedules migrated');
}

List<String> _generateDatesForDay(String dayName, {int months = 3}) {
  final dates = <String>[];
  final dayMap = {
    'Monday': DateTime.monday,
    'Tuesday': DateTime.tuesday,
    'Wednesday': DateTime.wednesday,
    'Thursday': DateTime.thursday,
    'Friday': DateTime.friday,
    'Saturday': DateTime.saturday,
    'Sunday': DateTime.sunday,
  };
  
  final targetDay = dayMap[dayName]!;
  final now = DateTime.now();
  final endDate = DateTime(now.year, now.month + months, now.day);
  
  DateTime current = now;
  while (current.isBefore(endDate)) {
    if (current.weekday == targetDay) {
      dates.add(_formatDate(current));
    }
    current = current.add(const Duration(days: 1));
  }
  
  return dates;
}
```

---

## ✅ Implementation Checklist

### **Phase 1: Core Model** ✅
- [✅] Update ScheduleModel with new fields
- [✅] Add helper methods
- [✅] Update fromFirestore/toFirestore
- [✅] Add table_calendar package

### **Phase 2: Service Layer**
- [ ] Update FirestoreService with date-based queries
- [ ] Add cancelSchedule method
- [ ] Add batchCreateSchedules method
- [ ] Create NotificationService

### **Phase 3: UI Components**
- [ ] Create ScheduleCalendarWidget
- [ ] Create DayDetailSheet
- [ ] Create QuickAddScheduleDialog
- [ ] Create AdvancedScheduleBuilder
- [ ] Create CancelScheduleDialog

### **Phase 4: Page Updates**
- [ ] Update SchedulePage to calendar-first
- [ ] Fix dashboard to support optional day field
- [ ] Update schedule_details_screen
- [ ] Add view toggles (Calendar/List/Day/Week)

### **Phase 5: Integration**
- [ ] Wire up calendar events
- [ ] Test single schedule creation
- [ ] Test multi-date creation
- [ ] Test cancellation workflow
- [ ] Test notification sending

### **Phase 6: Migration**
- [ ] Create migration script
- [ ] Backup existing data
- [ ] Run migration
- [ ] Verify data integrity

---

## 🎯 Success Criteria

✅ Calendar view is primary interface (not list)  
✅ Month grid shows all scheduled dates at a glance  
✅ Click any date to view/add/edit schedules  
✅ Visual indicators show booking status (dots, colors)  
✅ Can create schedules for specific dates (single or multiple)  
✅ Cancelled schedules show clearly on calendar  
✅ Students receive notifications when schedules cancelled  
✅ Smooth month navigation  
✅ Responsive design (mobile shows compact calendar)  

---

## 🐛 Known Issues to Address

1. **Lint Errors:**
   - `dashboard_page.dart:683` - `day` field now String?
   - `schedule_details_screen.dart:139` - Same issue
   
   **Fix:** Use `schedule.displayDate` instead of `schedule.day`

2. **Backwards Compatibility:**
   - Old schedules with `day` field still work
   - New schedules use `date` field
   - Migration script will convert all

---

## 📚 Next Steps

1. **Run `flutter pub get`** to install table_calendar
2. **Create UI widgets** (calendar, dialogs, sheets)
3. **Update service layer** with new query methods
4. **Replace schedule page** with calendar view
5. **Test thoroughly** before migration
6. **Run data migration** script
7. **Deploy and monitor** for issues

**This is a major feature - proceed step by step!** 🚀
