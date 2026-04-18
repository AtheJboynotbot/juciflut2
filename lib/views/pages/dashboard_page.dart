import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/faculty_provider.dart';
import '../../models/schedule_model.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/skeleton_card.dart';
import '../../widgets/empty_state.dart';
import '../dashboard_shell.dart';
import 'schedule_page.dart' show AddScheduleDialog;

/// Dashboard page – Real-Time Status, stats cards, and Today's Schedule.
/// Matches the JuCi reference design layout.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FacultyProvider>(
      builder: (context, prov, _) {
        if (prov.isLoading) {
          return _buildSkeletonLoader();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            
            if (isMobile) {
              // Mobile: Stack vertically
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildStatusCard(context, prov),
                    const SizedBox(height: 12),
                    _buildStatCard('Today\'s Slots', '${prov.totalSlots}'),
                    const SizedBox(height: 12),
                    _buildStatCard(
                        'This Week', '${prov.weeklyConsultations}\nConsultations'),
                    const SizedBox(height: 16),
                    _buildTodayScheduleCard(context, prov),
                    const SizedBox(height: 16),
                    _buildPendingBookingsCard(context),
                  ],
                ),
              );
            }
            
            // Tablet/Desktop: Side by side
            return SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column: Status + Stats
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            _buildStatusCard(context, prov),
                            const SizedBox(height: 12),
                            _buildStatCard('Today\'s Slots', '${prov.totalSlots}'),
                            const SizedBox(height: 12),
                            _buildStatCard(
                                'This Week', '${prov.weeklyConsultations}\nConsultations'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Right column: Today's Schedule
                      Expanded(
                        flex: 6,
                        child: _buildTodayScheduleCard(context, prov),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPendingBookingsCard(context),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  //  Skeleton Loader (shown while loading)
  // -------------------------------------------------------------------------
  Widget _buildSkeletonLoader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        if (isMobile) {
          return SingleChildScrollView(
            child: Column(
              children: [
                const SkeletonStatsCard(),
                const SizedBox(height: 12),
                const SkeletonStatsCard(),
                const SizedBox(height: 12),
                const SkeletonStatsCard(),
                const SizedBox(height: 16),
                GlassmorphicCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonCard(height: 20, width: 150),
                      const SizedBox(height: 16),
                      SkeletonList(
                        itemCount: 3,
                        skeletonItem: const SkeletonScheduleCard(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        
        return SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  children: const [
                    SkeletonStatsCard(),
                    SizedBox(height: 12),
                    SkeletonStatsCard(),
                    SizedBox(height: 12),
                    SkeletonStatsCard(),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 6,
                child: GlassmorphicCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonCard(height: 20, width: 150),
                      const SizedBox(height: 16),
                      SkeletonList(
                        itemCount: 3,
                        skeletonItem: const SkeletonScheduleCard(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  //  Real-Time Status Card with 3 toggle buttons
  // -------------------------------------------------------------------------
  Widget _buildStatusCard(BuildContext context, FacultyProvider prov) {
    final currentStatus = prov.faculty?.availabilityStatus ?? 'away';

    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Real-Time Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kCardText,
            ),
          ),
          const SizedBox(height: 16),
          // Status toggle buttons
          _buildStatusButton(
            label: 'Available',
            isSelected: currentStatus == 'available',
            onTap: () => prov.updateStatus('available'),
          ),
          const SizedBox(height: 8),
          _buildStatusButton(
            label: 'Busy',
            isSelected: currentStatus == 'busy',
            onTap: () => prov.updateStatus('busy'),
          ),
          const SizedBox(height: 8),
          _buildStatusButton(
            label: 'Away',
            isSelected: currentStatus == 'away',
            onTap: () => prov.updateStatus('away'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? kVioletAccent : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? kVioletAccent : kCardText,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  //  Stat Cards (Slots, Booked, Weekly)
  // -------------------------------------------------------------------------
  Widget _buildStatCard(String label, String value) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Reduce padding on very small screens
        final horizontalPadding = constraints.maxWidth < 200 ? 12.0 : 24.0;
        final fontSize = constraints.maxWidth < 200 ? 12.0 : 14.0;
        
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: horizontalPadding),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.93),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: kCardText,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: kCardText,
                  fontSize: fontSize + 2,
                  fontWeight: FontWeight.w800,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  //  Today's Schedule Card
  // -------------------------------------------------------------------------
  Widget _buildTodayScheduleCard(BuildContext context, FacultyProvider prov) {
    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row - wrap on very small screens
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 350;
              
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's Schedule",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kCardText,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, MMM d, yyyy')
                              .format(DateTime.now()),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => AddScheduleDialog(prov: prov),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kVioletAccent,
                          side: const BorderSide(color: kVioletAccent, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        child: const Text(
                          'Add new Slots',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                );
              }
              
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's Schedule",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kCardText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          DateFormat('EEEE, MMM d, yyyy')
                              .format(DateTime.now()),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: OutlinedButton(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => AddScheduleDialog(prov: prov),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kVioletAccent,
                        side: const BorderSide(color: kVioletAccent, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        'Add new Slots',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          // Schedule list – show only slots whose end time hasn't passed yet
          Builder(builder: (context) {
            final upcoming = prov.todaySchedules
                .where((s) => !s.isPast)
                .toList();
            if (upcoming.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: EmptyDayScheduleState(
                  dayName: _dayNames[DateTime.now().weekday - 1],
                ),
              );
            }
            return Column(
              children: upcoming
                  .map((s) => _buildScheduleTile(context, prov, s))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildScheduleTile(
      BuildContext context, FacultyProvider prov, ScheduleModel schedule) {
    final isClass = schedule.type == 'class';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).pushNamed(
        '/schedule-details',
        arguments: schedule,
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isClass ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Time + type indicator
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: _typeColor(schedule.type),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.title.isNotEmpty ? schedule.title : schedule.type,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isClass ? Colors.grey.shade600 : kCardText,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  '${schedule.timeRange}  •  ${schedule.location}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          // Action buttons (only for non-class slots)
          if (!isClass) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: kVioletAccent,
              onPressed: () => _showEditSlotDialog(context, prov, schedule),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: Colors.redAccent,
              onPressed: () => prov.deleteSchedule(schedule.id),
              tooltip: 'Delete',
            ),
          ],
        ],
      ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'consultation':
        return kVioletAccent;
      case 'class':
        return Colors.grey;
      case 'meeting':
        return Colors.orange;
      default:
        return kVioletAccent;
    }
  }

  // -------------------------------------------------------------------------
  //  Add Slot Dialog
  // -------------------------------------------------------------------------
  /// Format a TimeOfDay as "8:00 AM".
  static String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Parse a stored time string (e.g. "8:00 AM" or "08:00") back to TimeOfDay.
  static TimeOfDay? _parseTime(String s) {
    if (s.isEmpty) return null;
    final upper = s.toUpperCase().trim();
    final isPm = upper.contains('PM');
    final cleaned = upper.replaceAll(RegExp(r'[APM ]'), '');
    final parts = cleaned.split(':');
    if (parts.length != 2) return null;
    var hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  // -------------------------------------------------------------------------
  //  Edit Slot Dialog
  // -------------------------------------------------------------------------
  void _showEditSlotDialog(
      BuildContext context, FacultyProvider prov, ScheduleModel schedule) {
    final titleCtrl = TextEditingController(text: schedule.title);
    final locationCtrl = TextEditingController(text: schedule.location);
    String selectedType = schedule.type;
    String selectedDay = schedule.displayDate; // Use displayDate helper for backwards compatibility
    TimeOfDay? startTime = _parseTime(schedule.timeStart);
    TimeOfDay? endTime = _parseTime(schedule.timeEnd);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Slot'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: locationCtrl,
                      decoration: const InputDecoration(labelText: 'Location'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedDay,
                      decoration: const InputDecoration(labelText: 'Day'),
                      items: _dayNames
                          .map((d) =>
                              DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedDay = v ?? selectedDay),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: ctx,
                                initialTime: startTime ?? const TimeOfDay(hour: 8, minute: 0),
                              );
                              if (picked != null) {
                                setDialogState(() => startTime = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Start Time'),
                              child: Text(
                                startTime != null ? _formatTime(startTime!) : 'Select',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: startTime != null ? kCardText : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: ctx,
                                initialTime: endTime ?? const TimeOfDay(hour: 9, minute: 30),
                              );
                              if (picked != null) {
                                setDialogState(() => endTime = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'End Time'),
                              child: Text(
                                endTime != null ? _formatTime(endTime!) : 'Select',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: endTime != null ? kCardText : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(
                            value: 'consultation', child: Text('Consultation')),
                        DropdownMenuItem(value: 'class', child: Text('Class')),
                        DropdownMenuItem(
                            value: 'meeting', child: Text('Meeting')),
                      ],
                      onChanged: (v) => setDialogState(
                          () => selectedType = v ?? selectedType),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kVioletAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: (startTime == null || endTime == null)
                      ? null
                      : () async {
                    final startSnap = startTime!;
                    final endSnap = endTime!;
                    try {
                      await prov.updateSchedule(schedule.id, {
                        'title': titleCtrl.text.trim(),
                        'location': locationCtrl.text.trim(),
                        'day': selectedDay,
                        'time_start': _formatTime(startSnap),
                        'time_end': _formatTime(endSnap),
                        'type': selectedType,
                      });
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Schedule updated!'),
                            backgroundColor: kVioletAccent,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      print('❌ [DashboardPage] Update error: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update: $e'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static const _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // -------------------------------------------------------------------------
  //  Pending Bookings Card
  // -------------------------------------------------------------------------
  Widget _buildPendingBookingsCard(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, bookProv, _) {
        final pending = bookProv.pendingBookings.take(3).toList();

        return GlassmorphicCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  const Text(
                    'Pending Bookings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kCardText,
                    ),
                  ),
                  if (bookProv.pendingCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${bookProv.pendingCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        context.read<FacultyProvider>().setNavIndex(2),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                          color: kVioletAccent,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (pending.isEmpty)
                // Empty state
                Row(children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.green.shade500, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'No pending requests',
                    style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500),
                  ),
                ])
              else
                ...pending.map(
                    (b) => _buildPendingTile(context, b)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingTile(
      BuildContext context, BookingModel booking) {
    final initial = booking.studentName.isNotEmpty
        ? booking.studentName[0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.orange.shade400,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  booking.studentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: kCardText,
                  ),
                ),
                Text(
                  booking.studentEmail,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (booking.studentDepartment
                    .isNotEmpty)
                  Text(
                    booking.studentDepartment,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                if (booking.reason.isNotEmpty)
                  Text(
                    booking.reason,
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: kCardText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Action buttons
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                    Icons.check_circle_outline,
                    size: 20),
                color: Colors.green.shade600,
                tooltip: 'Approve',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () =>
                    _quickApprove(context, booking),
              ),
              const SizedBox(height: 4),
              IconButton(
                icon: const Icon(Icons.info_outline,
                    size: 20),
                color: kVioletAccent,
                tooltip: 'View in Bookings',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => context
                    .read<FacultyProvider>()
                    .setNavIndex(2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _quickApprove(
      BuildContext context, BookingModel booking) async {
    try {
      await context
          .read<BookingProvider>()
          .approveBooking(booking.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Approved booking for ${booking.studentName}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
