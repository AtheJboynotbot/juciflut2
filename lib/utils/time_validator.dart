import 'package:flutter/material.dart';

class TimeValidator {
  /// True if the date+time combination is before now.
  static bool isTimePast({required DateTime date, required TimeOfDay time}) {
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    return dt.isBefore(DateTime.now());
  }

  /// True if ISO date string + time string (e.g. "10:00 AM") is in the past.
  static bool isTimeStringPast({required String date, required String timeStr}) {
    return isTimePast(date: DateTime.parse(date), time: parseTimeString(timeStr));
  }

  /// Next available time rounded up to nearest 30-min mark + buffer.
  static TimeOfDay getNextAvailableTime({int bufferMinutes = 30}) {
    final buf = DateTime.now().add(Duration(minutes: bufferMinutes));
    int h = buf.hour, m = buf.minute;
    if (m > 0 && m <= 30) {
      m = 30;
    } else if (m > 30) {
      m = 0;
      h = (h + 1) % 24;
    }
    return TimeOfDay(hour: h, minute: m);
  }

  /// Parse "10:00 AM" → TimeOfDay.
  static TimeOfDay parseTimeString(String timeStr) {
    timeStr = timeStr.trim().toUpperCase();
    final parts = timeStr.split(' ');
    final tp = parts[0].split(':');
    int h = int.parse(tp[0]);
    final m = int.parse(tp[1]);
    final isPM = parts.length > 1 && parts[1] == 'PM';
    if (isPM && h != 12) h += 12;
    if (!isPM && h == 12) h = 0;
    return TimeOfDay(hour: h, minute: m);
  }

  /// Format TimeOfDay → "10:00 AM".
  static String formatTimeOfDay(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  /// True if endTime is strictly after startTime.
  static bool isEndTimeValid({required TimeOfDay startTime, required TimeOfDay endTime}) {
    return (endTime.hour * 60 + endTime.minute) > (startTime.hour * 60 + startTime.minute);
  }

  /// Returns an error string, or null if valid.
  static String? validateTime({
    required DateTime date,
    required TimeOfDay? startTime,
    required TimeOfDay? endTime,
  }) {
    if (startTime == null) return 'Please select start time';
    if (endTime == null) return 'Please select end time';
    if (isTimePast(date: date, time: startTime)) return 'Start time cannot be in the past';
    if (!isEndTimeValid(startTime: startTime, endTime: endTime)) {
      return 'End time must be after start time';
    }
    return null;
  }

  /// Convert time string to minutes since midnight.
  static int timeToMinutes(String timeStr) {
    final t = parseTimeString(timeStr);
    return t.hour * 60 + t.minute;
  }

  /// True if two time ranges overlap (exclusive boundaries).
  static bool hasTimeOverlap(String s1, String e1, String s2, String e2) {
    final s1m = timeToMinutes(s1), e1m = timeToMinutes(e1);
    final s2m = timeToMinutes(s2), e2m = timeToMinutes(e2);
    return s1m < e2m && e1m > s2m;
  }
}
