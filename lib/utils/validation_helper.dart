import 'package:flutter/material.dart';
import 'logger.dart';

/// Comprehensive validation helper for form fields
class ValidationHelper {
  /// Validate email format
  /// 
  /// Returns error message if invalid, null if valid
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      ValidationLogger.failure('email', 'Email is required');
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      ValidationLogger.failure('email', 'Invalid email format: $value');
      return 'Please enter a valid email address';
    }

    ValidationLogger.success('email', value);
    return null;
  }

  /// Validate required field
  /// 
  /// Returns error message if empty, null if valid
  static String? validateRequired(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      ValidationLogger.failure(fieldName, 'Field is required');
      return '$fieldName is required';
    }

    ValidationLogger.success(fieldName, value);
    return null;
  }

  /// Validate phone number
  /// 
  /// Accepts formats: +639123456789, 09123456789, 9123456789
  /// Returns error message if invalid, null if valid
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      ValidationLogger.failure('phone', 'Phone number is required');
      return 'Phone number is required';
    }

    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Philippine phone number patterns
    final patterns = [
      RegExp(r'^\+639\d{9}$'),        // +639123456789
      RegExp(r'^09\d{9}$'),            // 09123456789
      RegExp(r'^9\d{9}$'),             // 9123456789
      RegExp(r'^\+63\d{10}$'),         // +63 followed by 10 digits
    ];

    final isValid = patterns.any((pattern) => pattern.hasMatch(cleaned));

    if (!isValid) {
      ValidationLogger.failure('phone', 'Invalid format: $value');
      return 'Please enter a valid Philippine phone number';
    }

    ValidationLogger.success('phone', value);
    return null;
  }

  /// Validate time format (e.g., "8:00 AM", "2:30 PM")
  /// 
  /// Returns error message if invalid, null if valid
  static String? validateTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      ValidationLogger.failure('time', 'Time is required');
      return 'Time is required';
    }

    final timeRegex = RegExp(
      r'^(1[0-2]|0?[1-9]):([0-5][0-9])\s?(AM|PM)$',
      caseSensitive: false,
    );

    if (!timeRegex.hasMatch(value.trim())) {
      ValidationLogger.failure('time', 'Invalid time format: $value');
      return 'Please enter time in format: 8:00 AM';
    }

    ValidationLogger.success('time', value);
    return null;
  }

  /// Validate that start time is before end time
  /// 
  /// Returns error message if invalid, null if valid
  static String? validateTimeRange(TimeOfDay? startTime, TimeOfDay? endTime) {
    if (startTime == null) {
      ValidationLogger.failure('timeRange', 'Start time is required');
      return 'Please select a start time';
    }

    if (endTime == null) {
      ValidationLogger.failure('timeRange', 'End time is required');
      return 'Please select an end time';
    }

    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (startMinutes >= endMinutes) {
      ValidationLogger.failure('timeRange', 'Start time must be before end time');
      return 'Start time must be before end time';
    }

    ValidationLogger.success('timeRange', '$startTime - $endTime');
    return null;
  }

  /// Validate time range with minimum duration
  /// 
  /// Returns error message if invalid, null if valid
  static String? validateTimeRangeWithDuration(
    TimeOfDay? startTime,
    TimeOfDay? endTime, {
    int minDurationMinutes = 30,
  }) {
    final basicValidation = validateTimeRange(startTime, endTime);
    if (basicValidation != null) return basicValidation;

    final startMinutes = startTime!.hour * 60 + startTime.minute;
    final endMinutes = endTime!.hour * 60 + endTime.minute;
    final duration = endMinutes - startMinutes;

    if (duration < minDurationMinutes) {
      ValidationLogger.failure(
        'timeRange',
        'Duration too short: $duration minutes (min: $minDurationMinutes)',
      );
      return 'Schedule must be at least $minDurationMinutes minutes long';
    }

    ValidationLogger.success('timeRange', 'Duration: $duration minutes');
    return null;
  }

  /// Validate text length
  /// 
  /// Returns error message if invalid, null if valid
  static String? validateLength(
    String? value, {
    int? minLength,
    int? maxLength,
    String fieldName = 'This field',
  }) {
    if (value == null || value.isEmpty) {
      return validateRequired(value, fieldName: fieldName);
    }

    if (minLength != null && value.length < minLength) {
      ValidationLogger.failure(fieldName, 'Too short: ${value.length} < $minLength');
      return '$fieldName must be at least $minLength characters';
    }

    if (maxLength != null && value.length > maxLength) {
      ValidationLogger.failure(fieldName, 'Too long: ${value.length} > $maxLength');
      return '$fieldName must be at most $maxLength characters';
    }

    ValidationLogger.success(fieldName, 'Length: ${value.length}');
    return null;
  }

  /// Validate URL format
  /// 
  /// Returns error message if invalid, null if valid
  static String? validateUrl(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      if (required) {
        ValidationLogger.failure('url', 'URL is required');
        return 'URL is required';
      }
      return null;
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value.trim())) {
      ValidationLogger.failure('url', 'Invalid URL format: $value');
      return 'Please enter a valid URL';
    }

    ValidationLogger.success('url', value);
    return null;
  }

  /// Validate dropdown selection
  /// 
  /// Returns error message if invalid, null if valid
  static String? validateSelection(dynamic value, {String fieldName = 'Selection'}) {
    if (value == null) {
      ValidationLogger.failure(fieldName, 'No selection made');
      return 'Please make a $fieldName';
    }

    ValidationLogger.success(fieldName, value.toString());
    return null;
  }

  /// Validate numeric value
  /// 
  /// Returns error message if invalid, null if valid
  static String? validateNumeric(
    String? value, {
    num? min,
    num? max,
    String fieldName = 'This field',
  }) {
    if (value == null || value.trim().isEmpty) {
      ValidationLogger.failure(fieldName, 'Value is required');
      return '$fieldName is required';
    }

    final number = num.tryParse(value);
    if (number == null) {
      ValidationLogger.failure(fieldName, 'Not a number: $value');
      return 'Please enter a valid number';
    }

    if (min != null && number < min) {
      ValidationLogger.failure(fieldName, 'Too small: $number < $min');
      return '$fieldName must be at least $min';
    }

    if (max != null && number > max) {
      ValidationLogger.failure(fieldName, 'Too large: $number > $max');
      return '$fieldName must be at most $max';
    }

    ValidationLogger.success(fieldName, number.toString());
    return null;
  }

  /// Validate date is not in the past
  /// 
  /// Returns error message if invalid, null if valid
  static String? validateFutureDate(DateTime? date, {String fieldName = 'Date'}) {
    if (date == null) {
      ValidationLogger.failure(fieldName, 'Date is required');
      return '$fieldName is required';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(date.year, date.month, date.day);

    if (selectedDate.isBefore(today)) {
      ValidationLogger.failure(fieldName, 'Date in past: $date');
      return 'Please select a future date';
    }

    ValidationLogger.success(fieldName, date.toString());
    return null;
  }

  /// Combine multiple validators
  /// 
  /// Returns first error found, or null if all pass
  static String? combine(List<String? Function()> validators) {
    for (final validator in validators) {
      final error = validator();
      if (error != null) return error;
    }
    return null;
  }
}
