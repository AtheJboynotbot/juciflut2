/// Utility functions for time parsing and comparison
/// 
/// Handles time strings in format "8:00 AM", "10:30 PM", etc.
class TimeUtils {
  /// Parse time string (e.g., "8:00 AM") to minutes since midnight
  /// 
  /// Returns total minutes for easy comparison
  /// Example: "8:00 AM" = 480 minutes, "2:30 PM" = 870 minutes
  static int parseTimeToMinutes(String timeStr) {
    try {
      // Clean the string
      final cleaned = timeStr.trim().toUpperCase();
      
      // Split into time and period (AM/PM)
      final parts = cleaned.split(' ');
      if (parts.length != 2) {
        throw FormatException('Invalid time format: $timeStr');
      }
      
      final timePart = parts[0];
      final period = parts[1];
      
      // Split hours and minutes
      final timeParts = timePart.split(':');
      if (timeParts.length != 2) {
        throw FormatException('Invalid time format: $timeStr');
      }
      
      int hours = int.parse(timeParts[0]);
      final minutes = int.parse(timeParts[1]);
      
      // Validate
      if (hours < 1 || hours > 12) {
        throw FormatException('Hours must be between 1 and 12: $timeStr');
      }
      if (minutes < 0 || minutes > 59) {
        throw FormatException('Minutes must be between 0 and 59: $timeStr');
      }
      
      // Convert to 24-hour format
      if (period == 'PM' && hours != 12) {
        hours += 12;
      } else if (period == 'AM' && hours == 12) {
        hours = 0;
      }
      
      return (hours * 60) + minutes;
    } catch (e) {
      throw FormatException('Failed to parse time "$timeStr": $e');
    }
  }
  
  /// Check if two time ranges overlap
  /// 
  /// Returns true if the ranges overlap (excluding exact boundaries)
  /// Example:
  /// - "9:00 AM" to "11:00 AM" overlaps with "10:00 AM" to "12:00 PM" ✓
  /// - "9:00 AM" to "10:00 AM" does NOT overlap with "10:00 AM" to "11:00 AM" (back-to-back)
  static bool doTimeRangesOverlap({
    required String start1,
    required String end1,
    required String start2,
    required String end2,
  }) {
    final start1Minutes = parseTimeToMinutes(start1);
    final end1Minutes = parseTimeToMinutes(end1);
    final start2Minutes = parseTimeToMinutes(start2);
    final end2Minutes = parseTimeToMinutes(end2);
    
    // Validate ranges
    if (start1Minutes >= end1Minutes) {
      throw FormatException('Invalid range: $start1 to $end1 (start must be before end)');
    }
    if (start2Minutes >= end2Minutes) {
      throw FormatException('Invalid range: $start2 to $end2 (start must be before end)');
    }
    
    // Check for overlap (excluding exact boundaries - allows back-to-back slots)
    // Overlap occurs if:
    // - start1 is before end2 AND end1 is after start2
    // But we exclude exact matches (back-to-back is allowed)
    return (start1Minutes < end2Minutes) && (end1Minutes > start2Minutes) &&
           !(end1Minutes == start2Minutes || end2Minutes == start1Minutes);
  }
  
  /// Format minutes back to time string
  /// 
  /// Example: 480 minutes → "8:00 AM", 870 minutes → "2:30 PM"
  static String formatMinutesToTime(int minutes) {
    int hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    String period = 'AM';
    if (hours >= 12) {
      period = 'PM';
      if (hours > 12) {
        hours -= 12;
      }
    }
    if (hours == 0) {
      hours = 12;
    }
    
    return '${hours.toString()}:${mins.toString().padLeft(2, '0')} $period';
  }
  
  /// Get duration in minutes between two times
  static int getDurationMinutes(String startTime, String endTime) {
    final startMinutes = parseTimeToMinutes(startTime);
    final endMinutes = parseTimeToMinutes(endTime);
    return endMinutes - startMinutes;
  }
  
  /// Format duration to readable string
  /// 
  /// Example: 90 minutes → "1 hour 30 minutes"
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes minute${minutes != 1 ? 's' : ''}';
    }
    
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    if (mins == 0) {
      return '$hours hour${hours != 1 ? 's' : ''}';
    }
    
    return '$hours hour${hours != 1 ? 's' : ''} $mins minute${mins != 1 ? 's' : ''}';
  }
}
