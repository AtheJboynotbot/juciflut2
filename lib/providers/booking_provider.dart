import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

/// Provider for managing booking-related state
/// 
/// Handles:
/// - Streaming bookings from Firestore
/// - Creating, approving, rejecting, cancelling bookings
/// - Filtering bookings by status
/// - Tracking loading states and errors
class BookingProvider with ChangeNotifier {
  final BookingService _bookingService = BookingService();

  // ---- State variables ----------------------------------------------------
  List<BookingModel> _allBookings = [];
  List<BookingModel> _filteredBookings = [];
  String _selectedStatus = 'all'; // 'all' | 'pending' | 'approved' | 'rejected' | 'completed' | 'cancelled'
  bool _isLoading = false;
  String? _error;

  // ---- Stream subscription ------------------------------------------------
  StreamSubscription? _bookingsSub;

  // ---- Getters ------------------------------------------------------------
  List<BookingModel> get allBookings => _allBookings;
  List<BookingModel> get filteredBookings => _filteredBookings;
  String get selectedStatus => _selectedStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Derived getters
  List<BookingModel> get pendingBookings =>
      _allBookings.where((b) => b.status == BookingStatus.pending).toList();

  List<BookingModel> get approvedBookings =>
      _allBookings.where((b) => b.status == BookingStatus.approved).toList();

  List<BookingModel> get completedBookings =>
      _allBookings.where((b) => b.status == BookingStatus.completed).toList();

  List<BookingModel> get rejectedBookings =>
      _allBookings.where((b) => b.status == BookingStatus.rejected).toList();

  List<BookingModel> get cancelledBookings =>
      _allBookings.where((b) => b.status == BookingStatus.cancelled).toList();

  int get pendingCount => pendingBookings.length;
  int get approvedCount => approvedBookings.length;
  int get completedCount => completedBookings.length;

  // =========================================================================
  // INITIALIZATION
  // =========================================================================

  /// Initialize booking stream for a specific faculty
  void initForFaculty(String facultyId) {
    print('🔵 [BookingProvider] Initializing for faculty: $facultyId');
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Cancel existing subscription
    _bookingsSub?.cancel();

    // Start streaming all bookings
    _bookingsSub = _bookingService.streamBookingsForFaculty(facultyId).listen(
      (bookings) {
        print('🔵 [BookingProvider] Received ${bookings.length} bookings');
        _allBookings = bookings;
        _isLoading = false;
        _error = null;
        _applyFilter();
      },
      onError: (e) {
        print('❌ [BookingProvider] Error: $e');
        _error = 'Failed to load bookings: $e';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // =========================================================================
  // FILTER OPERATIONS
  // =========================================================================

  /// Set filter status and update filtered bookings
  void setFilter(String status) {
    print('🔍 [BookingProvider] Setting filter to: $status');
    _selectedStatus = status;
    _applyFilter();
  }

  /// Apply current filter to bookings
  void _applyFilter() {
    if (_selectedStatus == 'all') {
      _filteredBookings = List.from(_allBookings);
    } else {
      _filteredBookings = _allBookings
          .where((booking) => booking.status == _selectedStatus)
          .toList();
    }

    print('🔍 [BookingProvider] Filtered: ${_filteredBookings.length} bookings');
    notifyListeners();
  }

  // =========================================================================
  // BOOKING CRUD OPERATIONS
  // =========================================================================

  /// Create a new booking request
  Future<void> createBooking({
    required String scheduleId,
    required String facultyId,
    required String studentEmail,
    required String studentName,
    required String studentDepartment,
    required String reason,
  }) async {
    try {
      print('📝 [BookingProvider] Creating booking...');
      _error = null;

      await _bookingService.createBooking(
        scheduleId: scheduleId,
        facultyId: facultyId,
        studentEmail: studentEmail,
        studentName: studentName,
        studentDepartment: studentDepartment,
        reason: reason,
      );

      print('✅ [BookingProvider] Booking created successfully');
    } catch (e) {
      print('❌ [BookingProvider] Error creating booking: $e');
      _error = 'Failed to create booking: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Approve a pending booking
  Future<void> approveBooking(String bookingId) async {
    try {
      print('✅ [BookingProvider] Approving booking: $bookingId');
      _error = null;

      await _bookingService.approveBooking(bookingId);

      print('✅ [BookingProvider] Booking approved successfully');
    } catch (e) {
      print('❌ [BookingProvider] Error approving booking: $e');
      _error = 'Failed to approve booking: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Reject a pending booking
  Future<void> rejectBooking(String bookingId, {String? rejectionReason}) async {
    try {
      print('❌ [BookingProvider] Rejecting booking: $bookingId');
      _error = null;

      await _bookingService.rejectBooking(
        bookingId,
        rejectionReason: rejectionReason,
      );

      print('✅ [BookingProvider] Booking rejected successfully');
    } catch (e) {
      print('❌ [BookingProvider] Error rejecting booking: $e');
      _error = 'Failed to reject booking: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Cancel a booking
  Future<void> cancelBooking(String bookingId, {String? cancellationReason}) async {
    try {
      print('🚫 [BookingProvider] Cancelling booking: $bookingId');
      _error = null;

      await _bookingService.cancelBooking(
        bookingId,
        cancellationReason: cancellationReason,
      );

      print('✅ [BookingProvider] Booking cancelled successfully');
    } catch (e) {
      print('❌ [BookingProvider] Error cancelling booking: $e');
      _error = 'Failed to cancel booking: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Mark a booking as completed
  Future<void> completeBooking(String bookingId) async {
    try {
      print('🎯 [BookingProvider] Completing booking: $bookingId');
      _error = null;

      await _bookingService.completeBooking(bookingId);

      print('✅ [BookingProvider] Booking completed successfully');
    } catch (e) {
      print('❌ [BookingProvider] Error completing booking: $e');
      _error = 'Failed to complete booking: $e';
      notifyListeners();
      rethrow;
    }
  }

  // =========================================================================
  // UTILITY METHODS
  // =========================================================================

  /// Clear any error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset provider state
  void reset() {
    print('🔄 [BookingProvider] Resetting...');
    _bookingsSub?.cancel();
    _allBookings = [];
    _filteredBookings = [];
    _selectedStatus = 'all';
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  // =========================================================================
  // CLEANUP
  // =========================================================================

  @override
  void dispose() {
    _bookingsSub?.cancel();
    super.dispose();
  }
}
