import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/faculty_model.dart';
import '../models/schedule_model.dart';
import '../utils/time_utils.dart';
import '../utils/time_validator.dart';

/// Centralized Firestore service for all database operations.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'facconsult-firebase',
  );

  // ---------------------------------------------------------------------------
  //  FACULTY OPERATIONS (reads from 'faculty' collection)
  // ---------------------------------------------------------------------------

  /// Real-time stream of the faculty doc matched by email.
  /// OPTIMIZED: tries cached doc ID first (instant), falls back to email query.
  Stream<FacultyModel?> facultyStreamByEmail(String email) async* {
    final prefs = await SharedPreferences.getInstance();
    final cachedDocId = prefs.getString('faculty_doc_id_$email');

    // Validate cache if present
    if (cachedDocId != null) {
      final testSnap = await _db.collection('faculty').doc(cachedDocId).get();
      if (!testSnap.exists) {
        // Cache stale, clear it
        await prefs.remove('faculty_doc_id_$email');
      } else {
        // Cache valid — use direct doc stream (FAST)
        await for (final snap in _db.collection('faculty').doc(cachedDocId).snapshots()) {
          yield snap.exists ? FacultyModel.fromFirestore(snap) : null;
        }
        return; // Stream ended (shouldn't happen)
      }
    }

    // No cache or cache was stale — use query stream (SLOW)
    await for (final querySnap in _db
        .collection('faculty')
        .where('email', isEqualTo: email)
        .limit(1)
        .snapshots()) {
      if (querySnap.docs.isEmpty) {
        yield null;
      } else {
        final doc = querySnap.docs.first;
        // Cache the doc ID for next time
        await prefs.setString('faculty_doc_id_$email', doc.id);
        yield FacultyModel.fromFirestore(doc);
      }
    }
  }

  /// Create a new faculty document (first-time login fallback).
  Future<DocumentReference> createFacultyDoc(Map<String, dynamic> data) async {
    return await _db.collection('faculty').add(data);
  }

  /// Update the faculty's real-time availability status.
  Future<void> updateStatus(String facultyDocId, String status) async {
    await _db.collection('faculty').doc(facultyDocId).update({'availability_status': status});
  }

  /// Update faculty profile fields.
  Future<void> updateProfile(String facultyDocId, Map<String, dynamic> data) async {
    print('🔵 [FirestoreService.updateProfile] Doc: $facultyDocId');
    print('🔵 [FirestoreService.updateProfile] Data: $data');
    try {
      await _db.collection('faculty').doc(facultyDocId).update(data);
      print('✅ [FirestoreService.updateProfile] SUCCESS');
    } catch (e) {
      print('❌ [FirestoreService.updateProfile] FAILED: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  //  SCHEDULE OPERATIONS
  // ---------------------------------------------------------------------------

  /// Real-time stream of all schedules for a faculty member.
  /// Results are sorted chronologically by date then time_start.
  /// Legacy day-based schedules (no date field) appear last.
  Stream<List<ScheduleModel>> schedulesStream(String facultyId) {
    final todayIso = DateFormat('yyyy-MM-dd').format(DateTime.now());
    print('🔵 [schedulesStream] faculty=$facultyId today=$todayIso');
    return _db
        .collection('schedules')
        .where('faculty_id', isEqualTo: facultyId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) {
          print('🔵 [schedulesStream] Received ${snap.docs.length} schedules');
          final all = snap.docs
              .map((doc) => ScheduleModel.fromFirestore(doc))
              .where((s) => !s.isPast) // hide past end-times
              .toList();
          all.sort((a, b) {
            final dateA = a.date ?? '9999-99-99';
            final dateB = b.date ?? '9999-99-99';
            final cmp = dateA.compareTo(dateB);
            return cmp != 0 ? cmp : a.timeStart.compareTo(b.timeStart);
          });
          return all;
        });
  }

  /// Stream of today's ACTIVE schedules for a faculty member.
  /// Queries by ISO date string so only date-specific schedules are returned.
  Stream<List<ScheduleModel>> todaySchedulesStream(String facultyId) {
    final todayIso = DateFormat('yyyy-MM-dd').format(DateTime.now());
    print('🔵 [todaySchedulesStream] today=$todayIso faculty=$facultyId');
    return _db
        .collection('schedules')
        .where('faculty_id', isEqualTo: facultyId)
        .where('date', isEqualTo: todayIso)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => ScheduleModel.fromFirestore(doc))
              .toList()
            ..sort((a, b) => a.timeStart.compareTo(b.timeStart));
          return list;
        });
  }

  /// Batch-create schedules on multiple dates, checking conflicts on each.
  ///
  /// Throws an [Exception] listing all conflicting dates if any are found.
  /// Returns the list of created document IDs on success.
  Future<List<String>> batchCreateSchedules({
    required List<String> dates,
    required String facultyId,
    required String timeStart,
    required String timeEnd,
    required String type,
    required String title,
    required String location,
  }) async {
    print('📝 [batchCreateSchedules] ${dates.length} date(s) for $facultyId');

    // 1. Pre-check all dates for conflicts
    final conflictDates = <String>[];
    for (final date in dates) {
      final conflict = await checkScheduleConflict(
        facultyId: facultyId,
        date: date,
        timeStart: timeStart,
        timeEnd: timeEnd,
      );
      if (conflict != null) conflictDates.add(date);
    }

    if (conflictDates.isNotEmpty) {
      final labels = conflictDates
          .map((d) => DateFormat('MMM d, yyyy').format(DateTime.parse(d)))
          .join(', ');
      throw Exception('Conflicts found on: $labels');
    }

    // 2. No conflicts — create all
    final createdIds = <String>[];
    for (final date in dates) {
      final schedule = ScheduleModel(
        id: '',
        facultyId: facultyId,
        date: date,
        timeStart: timeStart,
        timeEnd: timeEnd,
        type: type,
        title: title,
        location: location,
        status: 'active',
        createdAt: DateTime.now(),
      );
      final docRef =
          await _db.collection('schedules').add(schedule.toFirestore());
      createdIds.add(docRef.id);
      print('✅ Created schedule for $date (${docRef.id})');
    }

    print('✅ [batchCreateSchedules] Created ${createdIds.length} schedule(s)');
    return createdIds;
  }

  /// Validate schedule for conflicts
  /// 
  /// Checks if a new schedule conflicts with existing schedules for the faculty
  /// Returns null if valid, or a ScheduleConflict object if there's a conflict
  /// 
  /// Business Rules:
  /// - Same day, overlapping times = conflict
  /// - Different days = no conflict
  /// - Back-to-back slots (9-10 AM, 10-11 AM) = no conflict
  Future<ScheduleConflict?> validateSchedule({
    required String facultyId,
    required String day,
    required String timeStart,
    required String timeEnd,
    String? excludeScheduleId, // For updates - exclude this ID from conflict check
  }) async {
    print('🔍 [validateSchedule] Checking conflicts for $day $timeStart-$timeEnd');
    
    try {
      // Get all schedules for this faculty on this day
      final querySnapshot = await _db
          .collection('schedules')
          .where('faculty_id', isEqualTo: facultyId)
          .where('day', isEqualTo: day)
          .get();
      
      print('🔍 [validateSchedule] Found ${querySnapshot.docs.length} schedules on $day');
      
      // Check each existing schedule for overlap
      for (final doc in querySnapshot.docs) {
        // Skip if this is the schedule being updated
        if (excludeScheduleId != null && doc.id == excludeScheduleId) {
          continue;
        }
        
        final existing = ScheduleModel.fromFirestore(doc);
        
        // Check for time overlap
        final hasOverlap = TimeUtils.doTimeRangesOverlap(
          start1: timeStart,
          end1: timeEnd,
          start2: existing.timeStart,
          end2: existing.timeEnd,
        );
        
        if (hasOverlap) {
          print('⚠️ [validateSchedule] CONFLICT DETECTED with schedule ${doc.id}');
          return ScheduleConflict(
            conflictingSchedule: existing,
            message: 'Time slot overlaps with existing ${existing.type}: '
                '${existing.timeStart} - ${existing.timeEnd}',
          );
        }
      }
      
      print('✅ [validateSchedule] No conflicts found');
      return null; // No conflict
    } catch (e) {
      print('❌ [validateSchedule] Error: $e');
      rethrow;
    }
  }

  /// Check if a new schedule conflicts with existing ACTIVE schedules (date-based).
  ///
  /// Returns the conflicting [ScheduleModel] if found, or null if the slot is free.
  /// Pass [excludeScheduleId] when editing an existing slot so it isn't compared with itself.
  Future<ScheduleModel?> checkScheduleConflict({
    required String facultyId,
    required String date,
    required String timeStart,
    required String timeEnd,
    String? excludeScheduleId,
  }) async {
    print('🔍 [checkScheduleConflict] $date $timeStart–$timeEnd');
    // Reject immediately if the requested start time is already past.
    if (TimeValidator.isTimeStringPast(date: date, timeStr: timeStart)) {
      throw Exception('Cannot create schedule for a time that has already passed');
    }
    try {
      final snap = await _db
          .collection('schedules')
          .where('faculty_id', isEqualTo: facultyId)
          .where('date', isEqualTo: date)
          .where('status', isEqualTo: 'active')
          .get();

      for (final doc in snap.docs) {
        if (excludeScheduleId != null && doc.id == excludeScheduleId) continue;
        final existing = ScheduleModel.fromFirestore(doc);
        try {
          final overlaps = TimeUtils.doTimeRangesOverlap(
            start1: timeStart,
            end1: timeEnd,
            start2: existing.timeStart,
            end2: existing.timeEnd,
          );
          if (overlaps) {
            print('❌ [checkScheduleConflict] Conflict with ${doc.id}');
            return existing;
          }
        } catch (e) {
          print('⚠️ [checkScheduleConflict] Time parse error: $e');
        }
      }
      print('✅ [checkScheduleConflict] No conflicts');
      return null;
    } catch (e) {
      print('❌ [checkScheduleConflict] Error: $e');
      rethrow;
    }
  }

  /// Cancel all pending/approved bookings for a schedule.
  ///
  /// Returns a list of the affected booking data maps (for notification purposes).
  Future<List<Map<String, dynamic>>> cancelBookingsForSchedule(
      String scheduleId, String cancellationReason) async {
    print('🔵 [cancelBookingsForSchedule] schedule: $scheduleId');
    final snap = await _db
        .collection('bookings')
        .where('schedule_id', isEqualTo: scheduleId)
        .where('status', whereIn: ['pending', 'approved'])
        .get();

    final affected = <Map<String, dynamic>>[];
    for (final doc in snap.docs) {
      await doc.reference.update({
        'status': 'cancelled_by_faculty',
        'cancellation_reason': cancellationReason,
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      affected.add(doc.data());
    }
    print('✅ [cancelBookingsForSchedule] Cancelled ${affected.length} bookings');
    return affected;
  }

  /// Add a new schedule slot.
  Future<DocumentReference> addSchedule(ScheduleModel schedule) async {
    print('🔵 [FirestoreService.addSchedule] Attempting to add to Firestore...');
    print('🔵 [FirestoreService.addSchedule] Data: ${schedule.toFirestore()}');
    try {
      final docRef = await _db.collection('schedules').add(schedule.toFirestore());
      print('✅ [FirestoreService.addSchedule] SUCCESS - Doc ID: ${docRef.id}');
      return docRef;
    } catch (e, stackTrace) {
      print('❌ [FirestoreService.addSchedule] FAILED!');
      print('❌ Error: $e');
      print('❌ Stack: $stackTrace');
      rethrow;
    }
  }

  /// Update an existing schedule slot.
  Future<void> updateSchedule(String id, Map<String, dynamic> data) async {
    await _db.collection('schedules').doc(id).update(data);
  }

  /// Delete a schedule slot.
  Future<void> deleteSchedule(String id) async {
    await _db.collection('schedules').doc(id).delete();
  }

  // ---------------------------------------------------------------------------
  //  DASHBOARD STATS (aggregated from schedules)
  // ---------------------------------------------------------------------------

  /// Get the total number of slots for a faculty on a given day.
  Stream<int> totalSlotsStream(String facultyId, String dayName) {
    return _db
        .collection('schedules')
        .where('faculty_id', isEqualTo: facultyId)
        .where('day', isEqualTo: dayName)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Get the number of booked slots for a faculty on a given day.
  Stream<int> bookedSlotsStream(String facultyId, String dayName) {
    return _db
        .collection('schedules')
        .where('faculty_id', isEqualTo: facultyId)
        .where('day', isEqualTo: dayName)
        .where('isBooked', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Get this week's total consultation count for a faculty.
  Stream<int> weeklyConsultationsStream(String facultyId) {
    return _db
        .collection('schedules')
        .where('faculty_id', isEqualTo: facultyId)
        .where('type', isEqualTo: 'consultation')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ---------------------------------------------------------------------------
  //  DEPARTMENT OPERATIONS
  // ---------------------------------------------------------------------------

  /// Stream of all departments for dropdown selection.
  Stream<List<Map<String, String>>> departmentsStream() {
    return _db
        .collection('departments')
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {
                  'id': doc.id,
                  'name': doc.data()['name'] as String? ?? 'Unknown',
                })
            .toList());
  }

  /// Fix corrupted profile image URLs by removing all whitespace characters
  Future<void> fixProfileImageUrl(String facultyId) async {
    try {
      final docRef = _db.collection('faculty').doc(facultyId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        print('⚠️ [fixProfileImageUrl] Document does not exist: $facultyId');
        return;
      }
      
      final data = doc.data();
      final currentUrl = data?['profile_image_url'];
      
      print('🔍 [fixProfileImageUrl] Checking URL for $facultyId');
      print('   Type: ${currentUrl.runtimeType}');
      print('   IsNull: ${currentUrl == null}');
      
      if (currentUrl == null) {
        print('   URL is null, skipping');
        return;
      }
      
      final urlString = currentUrl.toString();
      print('   Length: ${urlString.length}');
      print('   Raw bytes: ${urlString.codeUnits}');
      
      if (urlString.isEmpty) {
        print('   URL is empty, skipping');
        return;
      }
      
      // Remove ALL whitespace: spaces, newlines (\n=10), tabs (\t=9), etc.
      final fixedUrl = urlString.replaceAll(RegExp(r'\s+'), '');
      
      print('   Contains whitespace: ${fixedUrl.length != urlString.length}');
      
      if (fixedUrl != urlString) {
        print('🔧 [FirestoreService] FIXING corrupted URL!');
        print('   Before (length ${urlString.length})');
        print('   After  (length ${fixedUrl.length})');
        await docRef.update({'profile_image_url': fixedUrl});
        print('✅ [FirestoreService] URL FIXED in database!');
      } else {
        print('✅ [FirestoreService] URL is already clean');
      }
    } catch (e) {
      print('❌ [fixProfileImageUrl] Error: $e');
    }
  }
}

/// Represents a schedule conflict detected during validation
class ScheduleConflict {
  final ScheduleModel conflictingSchedule;
  final String message;

  const ScheduleConflict({
    required this.conflictingSchedule,
    required this.message,
  });

  @override
  String toString() => message;
}
