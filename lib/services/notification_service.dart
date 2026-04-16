import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Handles student notification records for schedule cancellations.
///
/// Notification records are stored in the `notifications` Firestore collection
/// with status 'pending'. A Cloud Function or external service can then pick
/// them up and send the actual emails.
class NotificationService {
  static FirebaseFirestore get _db => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'facconsult-firebase',
      );

  /// Queue cancellation notifications for all affected students.
  ///
  /// Each booking in [bookings] represents one affected student.
  /// A Firestore record is created per student so it can be delivered
  /// asynchronously (e.g. via Firebase Cloud Functions + SendGrid).
  static Future<void> sendCancellationNotifications({
    required String scheduleId,
    required List<Map<String, dynamic>> bookings,
    required String facultyName,
    required String? scheduleDate,
    required String timeStart,
    required String timeEnd,
    required String location,
    required String reason,
  }) async {
    for (final booking in bookings) {
      try {
        final studentEmail = booking['student_email'] as String? ?? '';
        final studentName = booking['student_name'] as String? ?? 'Student';

        await _db.collection('notifications').add({
          'type': 'schedule_cancelled',
          'schedule_id': scheduleId,
          'student_email': studentEmail,
          'student_name': studentName,
          'faculty_name': facultyName,
          'schedule_date': scheduleDate ?? '',
          'time_start': timeStart,
          'time_end': timeEnd,
          'location': location,
          'reason': reason,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        print('📧 [NotificationService] Notification queued → $studentEmail');
        print('   Subject : Consultation Cancelled – $facultyName');
        print('   Date    : $scheduleDate  $timeStart – $timeEnd');
        if (reason.isNotEmpty) print('   Reason  : $reason');
      } catch (e) {
        print('❌ [NotificationService] Failed to queue notification: $e');
      }
    }
  }
}
