import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import 'notification_service.dart';

/// Service for managing consultation booking operations in Firestore
/// 
/// Handles CRUD operations for the 'bookings' collection and updates
/// the 'is_booked' status in the 'schedules' collection
class BookingService {
  /// Get the database ID from environment or use default
  String get _databaseId => 'facconsult-firebase';

  /// Get Firestore instance for the configured database
  FirebaseFirestore get _firestore {
    return FirebaseFirestore.instanceFor(
      app: FirebaseFirestore.instance.app,
      databaseId: _databaseId,
    );
  }

  // =============================================================================
  // CREATE OPERATIONS
  // =============================================================================

  /// Create a new booking request
  /// 
  /// This method:
  /// 1. Creates a booking document with status 'pending'
  /// 2. Does NOT update schedule.is_booked (only after approval)
  /// 
  /// Returns the created booking ID
  Future<String> createBooking({
    required String scheduleId,
    required String facultyId,
    required String studentEmail,
    required String studentName,
    required String studentDepartment,
    required String reason,
  }) async {
    print('📝 [BookingService] Creating booking for schedule: $scheduleId');

    // Create booking document
    final booking = {
      'schedule_id': scheduleId,
      'faculty_id': facultyId,
      'student_email': studentEmail,
      'student_name': studentName,
      'student_department': studentDepartment,
      'status': BookingStatus.pending,
      'reason': reason,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };

    final docRef = await _firestore.collection('bookings').add(booking);
    print('✅ [BookingService] Booking created: ${docRef.id}');

    return docRef.id;
  }

  // =============================================================================
  // UPDATE OPERATIONS
  // =============================================================================

  /// Approve a booking request
  /// 
  /// This method:
  /// 1. Updates booking status to 'approved'
  /// 2. Updates schedule.is_booked to true
  /// 3. Updates updatedAt timestamp
  /// 4. Fire-and-forget: queues a notification for the student
  Future<void> approveBooking(String bookingId) async {
    print('✅ [BookingService] Approving booking: $bookingId');

    // Get booking to find schedule_id and student details
    final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
    if (!bookingDoc.exists) {
      throw Exception('Booking not found');
    }

    final data = bookingDoc.data()!;
    final scheduleId = data['schedule_id'] as String;
    final studentEmail = data['student_email'] as String? ?? '';
    final studentName = data['student_name'] as String? ?? 'Student';
    final studentId = data['student_id'] as String? ?? '';
    final facultyId = data['faculty_id'] as String? ?? '';

    // Start a batch write
    final batch = _firestore.batch();

    // Update booking status
    batch.update(
      _firestore.collection('bookings').doc(bookingId),
      {
        'status': BookingStatus.approved,
        'updatedAt': Timestamp.now(),
      },
    );

    // Update schedule booking flag — write both field names for cross-platform compatibility
    batch.update(
      _firestore.collection('schedules').doc(scheduleId),
      {
        'is_booked': true,
        'isBooked': true,
      },
    );

    await batch.commit();
    print('✅ [BookingService] Booking approved and schedule marked as booked');

    // Fire-and-forget: notify student without blocking the approve flow
    () async {
      try {
        final results = await Future.wait([
          _firestore.collection('schedules').doc(scheduleId).get(),
          _firestore.collection('faculty').doc(facultyId).get(),
        ]);
        final schedData = results[0].data() as Map<String, dynamic>? ?? {};
        final facData = results[1].data() as Map<String, dynamic>? ?? {};
        final facultyName =
            '${facData['first_name'] ?? ''} ${facData['last_name'] ?? ''}'.trim();
        await NotificationService.sendBookingApprovedNotification(
          bookingId: bookingId,
          scheduleId: scheduleId,
          studentId: studentId,
          studentEmail: studentEmail,
          studentName: studentName,
          facultyName: facultyName,
          scheduleDate: schedData['date'] as String? ?? '',
          timeStart: schedData['time_start'] as String? ?? '',
          timeEnd: schedData['time_end'] as String? ?? '',
          location: schedData['location'] as String? ?? '',
        );
      } catch (e) {
        print('⚠️ [BookingService] Approve notification failed: $e');
      }
    }();
  }

  /// Reject a booking request
  /// 
  /// This method:
  /// 1. Updates booking status to 'rejected'
  /// 2. Optionally stores rejection reason
  /// 3. Does NOT update schedule.is_booked
  /// 4. Fire-and-forget: queues a notification for the student
  Future<void> rejectBooking(String bookingId, {String? rejectionReason}) async {
    print('❌ [BookingService] Rejecting booking: $bookingId');

    // Read booking first to capture student details for the notification
    final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
    if (!bookingDoc.exists) {
      throw Exception('Booking not found');
    }

    final data = bookingDoc.data()!;
    final scheduleId = data['schedule_id'] as String? ?? '';
    final studentEmail = data['student_email'] as String? ?? '';
    final studentName = data['student_name'] as String? ?? 'Student';
    final studentId = data['student_id'] as String? ?? '';
    final facultyId = data['faculty_id'] as String? ?? '';

    final updates = <String, dynamic>{
      'status': BookingStatus.rejected,
      'updatedAt': Timestamp.now(),
    };

    if (rejectionReason != null && rejectionReason.isNotEmpty) {
      updates['rejection_reason'] = rejectionReason;
    }

    await _firestore.collection('bookings').doc(bookingId).update(updates);
    print('✅ [BookingService] Booking rejected');

    // Fire-and-forget: notify student without blocking the reject flow
    () async {
      try {
        final results = await Future.wait([
          _firestore.collection('schedules').doc(scheduleId).get(),
          _firestore.collection('faculty').doc(facultyId).get(),
        ]);
        final schedData = results[0].data() as Map<String, dynamic>? ?? {};
        final facData = results[1].data() as Map<String, dynamic>? ?? {};
        final facultyName =
            '${facData['first_name'] ?? ''} ${facData['last_name'] ?? ''}'.trim();
        await NotificationService.sendBookingRejectedNotification(
          bookingId: bookingId,
          scheduleId: scheduleId,
          studentId: studentId,
          studentEmail: studentEmail,
          studentName: studentName,
          facultyName: facultyName,
          scheduleDate: schedData['date'] as String? ?? '',
          timeStart: schedData['time_start'] as String? ?? '',
          timeEnd: schedData['time_end'] as String? ?? '',
          location: schedData['location'] as String? ?? '',
          rejectionReason: rejectionReason ?? '',
        );
      } catch (e) {
        print('⚠️ [BookingService] Reject notification failed: $e');
      }
    }();
  }

  /// Cancel a booking
  /// 
  /// This method:
  /// 1. Updates booking status to 'cancelled'
  /// 2. If booking was approved, updates schedule.is_booked to false
  /// 3. Optionally stores cancellation reason
  Future<void> cancelBooking(String bookingId, {String? cancellationReason}) async {
    print('🚫 [BookingService] Cancelling booking: $bookingId');

    // Get booking to check current status and schedule_id
    final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
    if (!bookingDoc.exists) {
      throw Exception('Booking not found');
    }

    final data = bookingDoc.data()!;
    final currentStatus = data['status'] as String;
    final scheduleId = data['schedule_id'] as String;

    // Start a batch write
    final batch = _firestore.batch();

    // Update booking status
    final updates = {
      'status': BookingStatus.cancelled,
      'updatedAt': Timestamp.now(),
    };

    if (cancellationReason != null && cancellationReason.isNotEmpty) {
      updates['cancellation_reason'] = cancellationReason;
    }

    batch.update(
      _firestore.collection('bookings').doc(bookingId),
      updates,
    );

    // If booking was approved, unbook the schedule (both field names for cross-platform compatibility)
    if (currentStatus == BookingStatus.approved) {
      batch.update(
        _firestore.collection('schedules').doc(scheduleId),
        {
          'is_booked': false,
          'isBooked': false,
        },
      );
    }

    await batch.commit();
    print('✅ [BookingService] Booking cancelled');
  }

  /// Mark a booking as completed
  /// 
  /// This method:
  /// 1. Updates booking status to 'completed'
  /// 2. Sets completed_at timestamp
  /// 3. Keeps schedule.is_booked as true (historical record)
  Future<void> completeBooking(String bookingId) async {
    print('🎯 [BookingService] Completing booking: $bookingId');

    await _firestore.collection('bookings').doc(bookingId).update({
      'status': BookingStatus.completed,
      'completed_at': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });

    print('✅ [BookingService] Booking marked as completed');
  }

  // =============================================================================
  // READ OPERATIONS - STREAMS
  // =============================================================================

  /// Stream all bookings for a specific faculty
  /// 
  /// Returns real-time updates of bookings ordered by creation date (newest first)
  Stream<List<BookingModel>> streamBookingsForFaculty(String facultyId) {
    print('🔵 [BookingService] Streaming bookings for faculty: $facultyId');

    return _firestore
        .collection('bookings')
        .where('faculty_id', isEqualTo: facultyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print('🔵 [BookingService] Received ${snapshot.docs.length} bookings');
      return snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
    });
  }

  /// Stream pending bookings for a specific faculty
  /// 
  /// Returns real-time updates of bookings awaiting approval
  Stream<List<BookingModel>> streamPendingBookings(String facultyId) {
    print('🔵 [BookingService] Streaming pending bookings for faculty: $facultyId');

    return _firestore
        .collection('bookings')
        .where('faculty_id', isEqualTo: facultyId)
        .where('status', isEqualTo: BookingStatus.pending)
        .orderBy('createdAt', descending: false) // Oldest first for pending
        .snapshots()
        .map((snapshot) {
      print('🔵 [BookingService] Received ${snapshot.docs.length} pending bookings');
      return snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
    });
  }

  /// Stream approved bookings for a specific faculty
  /// 
  /// Returns real-time updates of approved/upcoming consultations
  Stream<List<BookingModel>> streamApprovedBookings(String facultyId) {
    print('🔵 [BookingService] Streaming approved bookings for faculty: $facultyId');

    return _firestore
        .collection('bookings')
        .where('faculty_id', isEqualTo: facultyId)
        .where('status', isEqualTo: BookingStatus.approved)
        .orderBy('createdAt', descending: false) // Oldest first
        .snapshots()
        .map((snapshot) {
      print('🔵 [BookingService] Received ${snapshot.docs.length} approved bookings');
      return snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
    });
  }

  /// Stream bookings by status for a specific faculty
  /// 
  /// Returns real-time updates of bookings filtered by status
  Stream<List<BookingModel>> streamBookingsByStatus(String facultyId, String status) {
    print('🔵 [BookingService] Streaming $status bookings for faculty: $facultyId');

    return _firestore
        .collection('bookings')
        .where('faculty_id', isEqualTo: facultyId)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print('🔵 [BookingService] Received ${snapshot.docs.length} $status bookings');
      return snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
    });
  }

  // =============================================================================
  // READ OPERATIONS - ONE-TIME
  // =============================================================================

  /// Get a single booking by ID
  Future<BookingModel?> getBooking(String bookingId) async {
    final doc = await _firestore.collection('bookings').doc(bookingId).get();
    if (!doc.exists) return null;
    return BookingModel.fromFirestore(doc);
  }

  /// Get all bookings for a schedule slot
  /// 
  /// Useful for checking if a schedule has any bookings before deletion
  Future<List<BookingModel>> getBookingsForSchedule(String scheduleId) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('schedule_id', isEqualTo: scheduleId)
        .get();

    return snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
  }

  /// Get booking statistics for a faculty
  Future<Map<String, int>> getBookingStats(String facultyId) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('faculty_id', isEqualTo: facultyId)
        .get();

    final stats = {
      'total': snapshot.docs.length,
      'pending': 0,
      'approved': 0,
      'rejected': 0,
      'completed': 0,
      'cancelled': 0,
    };

    for (final doc in snapshot.docs) {
      final status = doc.data()['status'] as String;
      stats[status] = (stats[status] ?? 0) + 1;
    }

    return stats;
  }

  // =============================================================================
  // DELETE OPERATIONS
  // =============================================================================

  /// Delete a booking (admin operation)
  /// 
  /// Warning: This permanently deletes the booking
  /// Consider using cancelBooking() instead for normal operations
  Future<void> deleteBooking(String bookingId) async {
    print('🗑️ [BookingService] Deleting booking: $bookingId');

    // Get booking to check if we need to unbook schedule
    final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
    if (!bookingDoc.exists) {
      print('⚠️ [BookingService] Booking not found');
      return;
    }

    final data = bookingDoc.data()!;
    final status = data['status'] as String;
    final scheduleId = data['schedule_id'] as String;

    // Start a batch write
    final batch = _firestore.batch();

    // Delete booking
    batch.delete(_firestore.collection('bookings').doc(bookingId));

    // If booking was approved, unbook the schedule
    if (status == BookingStatus.approved) {
      batch.update(
        _firestore.collection('schedules').doc(scheduleId),
        {
          'is_booked': false,
        },
      );
    }

    await batch.commit();
    print('✅ [BookingService] Booking deleted');
  }
}
