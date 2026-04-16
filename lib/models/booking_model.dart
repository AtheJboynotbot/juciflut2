import 'package:cloud_firestore/cloud_firestore.dart';

/// Booking model for consultation slot reservations
/// 
/// Firestore Collection: 'bookings'
/// 
/// Status flow:
/// - pending → approved/rejected
/// - approved → completed/cancelled
/// - rejected (terminal state)
/// - cancelled (terminal state)
class BookingModel {
  final String id;
  final String scheduleId;
  final String facultyId;
  final String studentEmail;
  final String studentName;
  final String studentDepartment;
  final String status; // 'pending' | 'approved' | 'rejected' | 'completed' | 'cancelled'
  final String reason; // Reason for booking
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Optional fields for additional context
  final String? rejectionReason;
  final String? cancellationReason;
  final DateTime? completedAt;

  BookingModel({
    required this.id,
    required this.scheduleId,
    required this.facultyId,
    required this.studentEmail,
    required this.studentName,
    required this.studentDepartment,
    required this.status,
    required this.reason,
    required this.createdAt,
    required this.updatedAt,
    this.rejectionReason,
    this.cancellationReason,
    this.completedAt,
  });

  /// Factory constructor to create BookingModel from Firestore document
  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      scheduleId: data['schedule_id'] as String,
      facultyId: data['faculty_id'] as String,
      studentEmail: data['student_email'] as String,
      studentName: data['student_name'] as String,
      studentDepartment: data['student_department'] as String,
      status: data['status'] as String,
      reason: data['reason'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      rejectionReason: data['rejection_reason'] as String?,
      cancellationReason: data['cancellation_reason'] as String?,
      completedAt: data['completed_at'] != null
          ? (data['completed_at'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert BookingModel to Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'schedule_id': scheduleId,
      'faculty_id': facultyId,
      'student_email': studentEmail,
      'student_name': studentName,
      'student_department': studentDepartment,
      'status': status,
      'reason': reason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
      if (cancellationReason != null) 'cancellation_reason': cancellationReason,
      if (completedAt != null) 'completed_at': Timestamp.fromDate(completedAt!),
    };
  }

  /// Create a copy with updated fields
  BookingModel copyWith({
    String? id,
    String? scheduleId,
    String? facultyId,
    String? studentEmail,
    String? studentName,
    String? studentDepartment,
    String? status,
    String? reason,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? rejectionReason,
    String? cancellationReason,
    DateTime? completedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      facultyId: facultyId ?? this.facultyId,
      studentEmail: studentEmail ?? this.studentEmail,
      studentName: studentName ?? this.studentName,
      studentDepartment: studentDepartment ?? this.studentDepartment,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Check if booking is pending approval
  bool get isPending => status == 'pending';

  /// Check if booking is approved
  bool get isApproved => status == 'approved';

  /// Check if booking is rejected
  bool get isRejected => status == 'rejected';

  /// Check if booking is completed
  bool get isCompleted => status == 'completed';

  /// Check if booking is cancelled
  bool get isCancelled => status == 'cancelled';

  /// Check if booking can be cancelled (pending or approved)
  bool get canBeCancelled => status == 'pending' || status == 'approved';

  /// Check if booking can be approved (pending only)
  bool get canBeApproved => status == 'pending';

  /// Check if booking can be rejected (pending only)
  bool get canBeRejected => status == 'pending';

  /// Check if booking can be marked as completed (approved only)
  bool get canBeCompleted => status == 'approved';

  @override
  String toString() {
    return 'BookingModel(id: $id, status: $status, student: $studentName, schedule: $scheduleId)';
  }
}

/// Booking status enum
class BookingStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  static const List<String> all = [
    pending,
    approved,
    rejected,
    completed,
    cancelled,
  ];

  static String getDisplayName(String status) {
    switch (status) {
      case pending:
        return 'Pending';
      case approved:
        return 'Approved';
      case rejected:
        return 'Rejected';
      case completed:
        return 'Completed';
      case cancelled:
        return 'Cancelled';
      default:
        return status;
    }
  }
}
