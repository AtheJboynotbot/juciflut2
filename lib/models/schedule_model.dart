import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/time_validator.dart';

/// Represents a schedule slot stored in the Firestore `schedules` collection.
/// 
/// **NEW: Date-specific scheduling system**
/// - Uses `date` field (YYYY-MM-DD) instead of recurring `day` field
/// - Supports cancellation with reason and notification tracking
/// - Status field tracks active/cancelled/rescheduled states
class ScheduleModel {
  final String id;
  final String facultyId;
  
  // NEW: Date-specific fields
  final String? date; // ISO date string: '2026-04-20' (YYYY-MM-DD)
  final String status; // 'active' | 'cancelled' | 'rescheduled'
  final String? cancellationReason; // Reason when cancelled
  final DateTime? cancelledAt; // Timestamp when cancelled
  
  // Legacy field for backwards compatibility
  final String? day; // 'Monday', 'Tuesday', etc. (deprecated)
  
  // Existing fields
  final String timeStart; // '08:00 AM'
  final String timeEnd; // '09:30 PM'
  final String type; // 'consultation' | 'class' | 'meeting'
  final String title;
  final String location;
  final bool isBooked; // Whether this consultation slot is booked
  final DateTime? createdAt;
  
  // Booking tracking
  final int maxBookings; // Maximum number of bookings allowed
  final int currentBookings; // Current number of bookings

  const ScheduleModel({
    required this.id,
    required this.facultyId,
    this.date, // NEW: Primary date field
    this.status = 'active', // NEW
    this.cancellationReason, // NEW
    this.cancelledAt, // NEW
    this.day, // Legacy, optional
    required this.timeStart,
    required this.timeEnd,
    this.type = 'consultation',
    this.title = '',
    this.location = '',
    this.isBooked = false,
    this.maxBookings = 3,
    this.currentBookings = 0,
    this.createdAt,
  });

  /// Create from Firestore document snapshot.
  /// Supports both snake_case (time_start) and camelCase (timeStart) keys
  /// for backwards compatibility.
  factory ScheduleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Helper to parse timestamps
    DateTime? parseTimestamp(dynamic raw) {
      if (raw == null) return null;
      try {
        if (raw is Timestamp) return raw.toDate();
        if (raw is DateTime) return raw;
        if (raw.runtimeType.toString().contains('Timestamp')) {
          return (raw as dynamic).toDate();
        }
      } catch (e) {
        print('⚠️ [ScheduleModel] Failed to parse timestamp: $e');
      }
      return null;
    }
    
    final createdAtDate = parseTimestamp(data['createdAt']);
    final cancelledAtDate = parseTimestamp(data['cancelledAt'] ?? data['cancelled_at']);
    
    return ScheduleModel(
      id: doc.id,
      facultyId: data['faculty_id'] ?? data['facultyId'] ?? '',
      date: data['date'], // NEW: ISO date string
      status: data['status'] ?? 'active', // NEW
      cancellationReason: data['cancellation_reason'] ?? data['cancellationReason'], // NEW
      cancelledAt: cancelledAtDate, // NEW
      day: data['day'], // Legacy field
      timeStart: data['time_start'] ?? data['timeStart'] ?? '',
      timeEnd: data['time_end'] ?? data['timeEnd'] ?? '',
      type: data['type'] ?? 'consultation',
      title: data['title'] ?? '',
      location: data['location'] ?? '',
      isBooked: data['is_booked'] ?? data['isBooked'] ?? false,
      maxBookings: data['max_bookings'] ?? data['maxBookings'] ?? 3,
      currentBookings: data['current_bookings'] ?? data['currentBookings'] ?? 0,
      createdAt: createdAtDate,
    );
  }

  /// Convert to Firestore-compatible map.
  /// Uses snake_case field names (faculty_id, time_start, time_end) as per schema.
  Map<String, dynamic> toFirestore() {
    return {
      'faculty_id': facultyId,
      if (date != null) 'date': date, // NEW: Primary date field
      'status': status, // NEW
      if (cancellationReason != null) 'cancellation_reason': cancellationReason, // NEW
      if (cancelledAt != null) 'cancelled_at': Timestamp.fromDate(cancelledAt!), // NEW
      if (day != null) 'day': day, // Legacy field (for backwards compatibility)
      'time_start': timeStart,
      'time_end': timeEnd,
      'type': type,
      'title': title,
      'location': location,
      'is_booked': isBooked,
      'isBooked': isBooked,
      'max_bookings': maxBookings,
      'current_bookings': currentBookings,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : Timestamp.fromDate(DateTime.now()),
    };
  }

  /// Create a copy with updated fields.
  ScheduleModel copyWith({
    String? date,
    String? status,
    String? cancellationReason,
    DateTime? cancelledAt,
    String? day,
    String? timeStart,
    String? timeEnd,
    String? type,
    String? title,
    String? location,
    bool? isBooked,
    int? maxBookings,
    int? currentBookings,
  }) {
    return ScheduleModel(
      id: id,
      facultyId: facultyId,
      date: date ?? this.date,
      status: status ?? this.status,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      day: day ?? this.day,
      timeStart: timeStart ?? this.timeStart,
      timeEnd: timeEnd ?? this.timeEnd,
      type: type ?? this.type,
      title: title ?? this.title,
      location: location ?? this.location,
      isBooked: isBooked ?? this.isBooked,
      maxBookings: maxBookings ?? this.maxBookings,
      currentBookings: currentBookings ?? this.currentBookings,
      createdAt: createdAt,
    );
  }

  /// Formatted time range for display (e.g. "8:00 AM – 9:30 AM").
  String get timeRange => '$timeStart – $timeEnd';
  
  /// Check if this schedule is cancelled
  bool get isCancelled => status == 'cancelled';
  
  /// Check if this schedule is active
  bool get isActive => status == 'active';
  
  /// Check if this schedule is fully booked
  bool get isFullyBooked => currentBookings >= maxBookings;
  
  /// Get available slots remaining
  int get availableSlots => maxBookings - currentBookings;
  
  /// Get DateTime object from date string
  DateTime? get dateTime {
    if (date == null) return null;
    try {
      return DateTime.parse(date!);
    } catch (e) {
      print('⚠️ [ScheduleModel] Failed to parse date: $date');
      return null;
    }
  }

  /// Day-of-week name derived from date (e.g. "Friday").
  String get dayName {
    final dt = dateTime;
    if (dt == null) return day ?? 'Unknown';
    return DateFormat('EEEE').format(dt);
  }

  /// Short date label (e.g. "Apr 20").
  String get shortDate {
    final dt = dateTime;
    if (dt == null) return date ?? '';
    return DateFormat('MMM d').format(dt);
  }

  /// Full formatted date (e.g. "Friday, Apr 20, 2026").
  String? get formattedDate {
    final dt = dateTime;
    if (dt == null) return null;
    return DateFormat('EEEE, MMM d, yyyy').format(dt);
  }

  /// Get display date (backwards-compat alias → dayName).
  String get displayDate => dayName;

  /// True when this schedule's end time is already in the past.
  bool get isPast {
    if (date == null) return false;
    try {
      final dt = DateTime.parse(date!);
      final end = TimeValidator.parseTimeString(timeEnd);
      return TimeValidator.isTimePast(date: dt, time: end);
    } catch (_) {
      return false;
    }
  }

  /// True when this schedule falls on today's date.
  bool get isToday {
    if (date == null) return false;
    try {
      final now = DateTime.now();
      final dt = DateTime.parse(date!);
      return dt.year == now.year && dt.month == now.month && dt.day == now.day;
    } catch (_) {
      return false;
    }
  }
}
