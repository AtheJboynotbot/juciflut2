# 🗓️ Calendar System - Quick Start Guide

## ✅ Phase 1 Complete!

**What's Done:**
- ✅ ScheduleModel updated with date-specific fields
- ✅ Backwards compatibility maintained (day field optional)
- ✅ table_calendar package installed (v3.1.3)
- ✅ Helper methods added (isCancelled, isActive, displayDate, etc.)
- ✅ All 51 tests passing
- ✅ Lint errors fixed

---

## 🚀 Next Steps - Implement Calendar UI

### **Step 1: Create Main Calendar Widget**

**File:** `lib/widgets/schedule_calendar_widget.dart`

```dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/schedule_model.dart';

class ScheduleCalendarWidget extends StatefulWidget {
  final String facultyId;
  final List<ScheduleModel> schedules;
  final DateTime focusedDay;
  final Function(DateTime) onDateSelected;
  final Function(DateTime) onMonthChanged;

  const ScheduleCalendarWidget({
    super.key,
    required this.facultyId,
    required this.schedules,
    required this.focusedDay,
    required this.onDateSelected,
    required this.onMonthChanged,
  });

  @override
  State<ScheduleCalendarWidget> createState() => _ScheduleCalendarWidgetState();
}

class _ScheduleCalendarWidgetState extends State<ScheduleCalendarWidget> {
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: widget.focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      
      // Load schedules for each day
      eventLoader: (day) => _getSchedulesForDate(day),
      
      // Styling
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: const Color(0xFF7C4DFF),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: const Color(0xFF7C4DFF).withOpacity(0.7),
          shape: BoxShape.circle,
        ),
        markerDecoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
      ),
      
      // Header styling
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      
      // Callbacks
      onDaySelected: (selectedDay, focusedDay) {
        setState(() => _selectedDay = selectedDay);
        widget.onDateSelected(selectedDay);
      },
      
      onPageChanged: (focusedDay) {
        widget.onMonthChanged(focusedDay);
      },
      
      // Custom builders
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, schedules) {
          if (schedules.isEmpty) return const SizedBox();
          
          final typedSchedules = schedules.cast<ScheduleModel>();
          return _buildScheduleMarkers(typedSchedules);
        },
      ),
    );
  }

  List<ScheduleModel> _getSchedulesForDate(DateTime date) {
    final dateStr = _formatDate(date);
    return widget.schedules
        .where((s) => s.date == dateStr && s.isActive)
        .toList();
  }

  Widget _buildScheduleMarkers(List<ScheduleModel> schedules) {
    final totalBookings = schedules.fold<int>(
      0,
      (sum, s) => sum + s.currentBookings,
    );
    
    final dotCount = totalBookings.clamp(0, 3);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        dotCount,
        (index) => Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: _getMarkerColor(schedules),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Color _getMarkerColor(List<ScheduleModel> schedules) {
    if (schedules.any((s) => s.isFullyBooked)) {
      return Colors.purple;
    }
    if (schedules.any((s) => s.currentBookings > 0)) {
      return Colors.orange;
    }
    return Colors.green;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
```

---

### **Step 2: Update Schedule Page**

**File:** `lib/views/pages/schedule_page.dart`

**Replace current implementation with:**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/faculty_provider.dart';
import '../../models/schedule_model.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/schedule_calendar_widget.dart';
import '../dashboard_shell.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime _focusedDay = DateTime.now();
  bool _showCalendarView = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<FacultyProvider>(
      builder: (context, prov, _) {
        if (prov.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: kVioletAccent),
          );
        }

        return SingleChildScrollView(
          child: GlassmorphicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 20),
                
                // Calendar or List View
                if (_showCalendarView)
                  _buildCalendarView(prov)
                else
                  _buildListView(prov),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'My Schedule',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kCardText,
          ),
        ),
        Row(
          children: [
            // View toggle
            IconButton(
              icon: Icon(
                _showCalendarView ? Icons.list : Icons.calendar_month,
                color: kVioletAccent,
              ),
              onPressed: () {
                setState(() => _showCalendarView = !_showCalendarView);
              },
              tooltip: _showCalendarView ? 'List View' : 'Calendar View',
            ),
            // Add button
            ElevatedButton.icon(
              onPressed: () => _showQuickAdd(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Schedule'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kVioletAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarView(FacultyProvider prov) {
    return SizedBox(
      height: 400,
      child: ScheduleCalendarWidget(
        facultyId: prov.faculty!.id,
        schedules: prov.allSchedules,
        focusedDay: _focusedDay,
        onDateSelected: (date) => _showDayDetail(date, prov),
        onMonthChanged: (date) => setState(() => _focusedDay = date),
      ),
    );
  }

  Widget _buildListView(FacultyProvider prov) {
    // Keep existing list view implementation
    final grouped = <String, List<ScheduleModel>>{};
    // ... existing grouping logic
    
    return Column(
      children: [
        const Text('List view - Use existing implementation'),
      ],
    );
  }

  void _showDayDetail(DateTime date, FacultyProvider prov) {
    final dateStr = _formatDate(date);
    final schedulesForDay = prov.allSchedules
        .where((s) => s.date == dateStr)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDateDisplay(date),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            
            if (schedulesForDay.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text(
                    'No schedules for this day',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: schedulesForDay.length,
                  itemBuilder: (context, index) {
                    final schedule = schedulesForDay[index];
                    return _buildScheduleCard(schedule, prov);
                  },
                ),
              ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showQuickAdd(date: date),
                icon: const Icon(Icons.add),
                label: const Text('Add Schedule for This Day'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kVioletAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(ScheduleModel schedule, FacultyProvider prov) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF2A2A3E),
      child: ListTile(
        leading: Icon(
          Icons.access_time,
          color: schedule.isCancelled ? Colors.red : kVioletAccent,
        ),
        title: Text(
          schedule.timeRange,
          style: TextStyle(
            color: Colors.white,
            decoration: schedule.isCancelled ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${schedule.type} - ${schedule.currentBookings}/${schedule.maxBookings} booked',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: schedule.isCancelled
            ? const Chip(
                label: Text('Cancelled', style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.red,
              )
            : null,
      ),
    );
  }

  void _showQuickAdd({DateTime? date}) {
    // TODO: Implement quick add dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quick Add dialog - To be implemented')),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateDisplay(DateTime date) {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
```

---

## 📝 Implementation Order

1. ✅ **Phase 1: Model Updates** - COMPLETE
2. **Phase 2: Calendar Widget** - Create schedule_calendar_widget.dart
3. **Phase 3: Update Schedule Page** - Add calendar view
4. **Phase 4: Day Detail Sheet** - Modal bottom sheet
5. **Phase 5: Quick Add Dialog** - Create schedule for date
6. **Phase 6: Service Updates** - Date-based queries

---

## 🎯 Current Status

✅ ScheduleModel supports both systems  
✅ Backwards compatible with day-based schedules  
✅ table_calendar package ready  
✅ All tests passing  
⏭️ Ready to implement calendar UI  

---

## 📚 Resources

- **Full Migration Guide:** `CALENDAR_MIGRATION_GUIDE.md`
- **table_calendar Docs:** https://pub.dev/packages/table_calendar
- **ScheduleModel:** `lib/models/schedule_model.dart`

---

## 💡 Tips

- **Test incrementally** - Add calendar view alongside existing list view
- **Use feature flags** - Toggle between old/new UI during development
- **Migrate gradually** - Start with new schedules, migrate old ones later
- **Monitor analytics** - Track which view users prefer

**You're ready to implement the calendar UI!** 🚀
