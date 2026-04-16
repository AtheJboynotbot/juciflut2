import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/faculty_model.dart';
import '../models/schedule_model.dart';
import '../services/firestore_service.dart';

/// Central state manager for the dashboard.
///
/// Optimized: only 3 Firestore streams (profile, allSchedules, todaySchedules).
/// Stats are derived locally from the schedule lists — no extra queries.
class FacultyProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // ---- State ---------------------------------------------------------------
  FacultyModel? _faculty;
  List<ScheduleModel> _todaySchedules = [];
  List<ScheduleModel> _allSchedules = [];
  bool _isLoading = true;
  String? _error;
  int _selectedNavIndex = 0;
  bool _initialized = false;

  // ---- Getters -------------------------------------------------------------
  FacultyModel? get faculty => _faculty;
  List<ScheduleModel> get todaySchedules => _todaySchedules;
  List<ScheduleModel> get allSchedules => _allSchedules;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get selectedNavIndex => _selectedNavIndex;

  // Derived stats — computed from allSchedules, no extra Firestore streams
  int get totalSlots => _todaySchedules.length;
  int get weeklyConsultations =>
      _allSchedules.where((s) => s.type == 'consultation').length;

  // ---- Stream subscriptions (only 3 instead of 6) -------------------------
  StreamSubscription? _facultySub;
  StreamSubscription? _todaySub;
  StreamSubscription? _allSchedulesSub;
  String? _currentFacultyDocId; // tracks which faculty doc schedules are bound to
  String? _currentUserEmail; // tracks which user email is currently loaded


  // =========================================================================
  //  INITIALIZATION – lookup faculty doc by email, subscribe to streams
  // =========================================================================
  void initForUser(User user) {
    final email = user.email ?? '';
    
    // Check if this is a different user - if so, reset everything
    if (_currentUserEmail != null && _currentUserEmail != email) {
      print('🔄 [initForUser] Different user detected! Resetting...');
      print('   Previous: $_currentUserEmail');
      print('   New: $email');
      reset();
    }
    
    // Prevent duplicate initialization on hot reload / rebuild
    if (_initialized && _faculty != null && _currentUserEmail == email) {
      print('⏭️ [initForUser] Already initialized for $email, skipping...');
      return;
    }
    
    _currentUserEmail = email;
    _initialized = true;
    _isLoading = true;
    _error = null;
    // Do NOT call notifyListeners() here — we're inside build cycle

    print('🔵 [initForUser] Email: $email');

    // Faculty profile stream — queries 'faculty' collection by email.
    // Whenever a faculty doc appears or changes, we (re-)start schedule streams.
    _facultySub?.cancel();
    _facultySub = _firestoreService.facultyStreamByEmail(email).listen(
      (faculty) {
        print('🔵 [initForUser] Faculty loaded: ${faculty?.id ?? "NULL"}');
        _faculty = faculty;
        if (_isLoading) _isLoading = false;
        notifyListeners();

        // Start or restart schedule streams when faculty doc appears / changes
        if (faculty != null && faculty.id != _currentFacultyDocId) {
          print('✅ [initForUser] Starting schedule streams for: ${faculty.id}');
          _currentFacultyDocId = faculty.id;
          
          // Fix any corrupted profile image URLs (run in background)
          _firestoreService.fixProfileImageUrl(faculty.id).then((_) {
            print('✅ [initForUser] Profile image URL check complete');
          }).catchError((e) {
            print('❌ [initForUser] Profile image URL fix error: $e');
          });
          
          _startScheduleStreams(faculty.id);
        } else if (faculty == null) {
          print('⚠️ [initForUser] No faculty document found for: $email');
        }
      },
      onError: (e) {
        print('❌ [initForUser] ERROR: $e');
        _error = 'Failed to load profile: $e';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Subscribe to schedule streams using the faculty document ID.
  void _startScheduleStreams(String facultyDocId) {
    // Today's schedule stream
    _todaySub?.cancel();
    _todaySub =
        _firestoreService.todaySchedulesStream(facultyDocId).listen(
      (schedules) {
        _todaySchedules = schedules;
        notifyListeners();
      },
      onError: (e) => debugPrint('Today schedules error: $e'),
    );

    // All schedules stream (for My Schedule page + derived stats)
    _allSchedulesSub?.cancel();
    _allSchedulesSub = _firestoreService.schedulesStream(facultyDocId).listen(
      (schedules) {
        _allSchedules = schedules;
        notifyListeners();
      },
      onError: (e) => debugPrint('All schedules error: $e'),
    );
  }

  // =========================================================================
  //  ACTIONS
  // =========================================================================

  /// Update the selected navigation index (Dashboard / My Schedule / Profile).
  void setNavIndex(int index) {
    _selectedNavIndex = index;
    notifyListeners();
  }

  /// Toggle real-time availability status (writes to Firestore instantly).
  Future<void> updateStatus(String newStatus) async {
    if (_faculty == null) return;
    try {
      await _firestoreService.updateStatus(_faculty!.id, newStatus);
    } catch (e) {
      _error = 'Failed to update status: $e';
      notifyListeners();
    }
  }

  /// Validate schedule for time conflicts
  /// 
  /// Returns null if valid, or ScheduleConflict if there's a conflict
  Future<dynamic> validateSchedule({
    required String day,
    required String timeStart,
    required String timeEnd,
    String? excludeScheduleId,
  }) async {
    if (_faculty == null) {
      throw Exception('Faculty not loaded');
    }
    
    return await _firestoreService.validateSchedule(
      facultyId: _faculty!.id,
      day: day,
      timeStart: timeStart,
      timeEnd: timeEnd,
      excludeScheduleId: excludeScheduleId,
    );
  }

  /// Add a new schedule slot.
  Future<void> addSchedule(ScheduleModel schedule) async {
    print('🔵 [addSchedule] Faculty: ${_faculty?.id ?? "NULL"}');
    print('🔵 [addSchedule] Data: ${schedule.toFirestore()}');
    try {
      final docRef = await _firestoreService.addSchedule(schedule);
      print('✅ [addSchedule] SUCCESS - Doc ID: ${docRef.id}');
    } catch (e) {
      print('❌ [addSchedule] ERROR: $e');
      _error = 'Failed to add schedule: $e';
      notifyListeners();
      rethrow; // Propagate error to UI
    }
  }

  /// Update an existing schedule slot.
  Future<void> updateSchedule(String id, Map<String, dynamic> data) async {
    print('🔵 [updateSchedule] Updating: $id with $data');
    try {
      await _firestoreService.updateSchedule(id, data);
      print('✅ [updateSchedule] SUCCESS');
    } catch (e) {
      print('❌ [updateSchedule] ERROR: $e');
      _error = 'Failed to update schedule: $e';
      notifyListeners();
      rethrow; // Propagate error to UI
    }
  }

  /// Cancel a schedule and all its active bookings.
  ///
  /// Returns a list of affected booking data maps so the caller can send
  /// notifications to the students.
  Future<List<Map<String, dynamic>>> cancelSchedule(
      String scheduleId, String reason) async {
    print('🔵 [cancelSchedule] id=$scheduleId reason="$reason"');
    try {
      await _firestoreService.updateSchedule(scheduleId, {
        'status': 'cancelled',
        'cancellation_reason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      final affected =
          await _firestoreService.cancelBookingsForSchedule(scheduleId, reason);
      print('✅ [cancelSchedule] Done. ${affected.length} bookings cancelled.');
      return affected;
    } catch (e) {
      print('❌ [cancelSchedule] ERROR: $e');
      _error = 'Failed to cancel schedule: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a schedule slot.
  Future<void> deleteSchedule(String id) async {
    try {
      await _firestoreService.deleteSchedule(id);
    } catch (e) {
      _error = 'Failed to delete schedule: $e';
      notifyListeners();
    }
  }

  /// Update faculty profile.
  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_faculty == null) {
      throw Exception('No faculty profile loaded');
    }
    
    // Clean profile_image_url to prevent corruption (remove ALL whitespace)
    if (data.containsKey('profile_image_url')) {
      final url = data['profile_image_url'];
      if (url is String) {
        data['profile_image_url'] = url.replaceAll(RegExp(r'\s+'), '');
      }
    }
    
    print('🔵 [updateProfile] Updating profile with: $data');
    try {
      await _firestoreService.updateProfile(_faculty!.id, data);
      print('✅ [updateProfile] SUCCESS');
    } catch (e) {
      print('❌ [updateProfile] ERROR: $e');
      _error = 'Failed to update profile: $e';
      notifyListeners();
      rethrow; // Propagate error to UI
    }
  }

  /// Clear any displayed error.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset all data when logging out or switching accounts
  void reset() {
    print('🔄 [FacultyProvider] Resetting provider...');
    
    // Cancel all subscriptions
    _facultySub?.cancel();
    _todaySub?.cancel();
    _allSchedulesSub?.cancel();
    
    // Clear all data
    _faculty = null;
    _todaySchedules = [];
    _allSchedules = [];
    _isLoading = false;
    _initialized = false;
    _currentFacultyDocId = null;
    _currentUserEmail = null;
    _error = null;
    
    print('✅ [FacultyProvider] Reset complete');
    notifyListeners();
  }

  // =========================================================================
  //  CLEANUP
  // =========================================================================
  @override
  void dispose() {
    _facultySub?.cancel();
    _todaySub?.cancel();
    _allSchedulesSub?.cancel();
    super.dispose();
  }
}
