import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a faculty member stored in the Firestore `faculty` collection.
///
/// Firestore document fields:
///   email, first_name, last_name, department_id,
///   availability_status (available | busy | away), profile_image_url,
///   date_of_birth, phone_number, office_location
class FacultyModel {
  final String id; // Firestore document ID
  final String email;
  final String firstName;
  final String lastName;
  final String departmentId;
  final String availabilityStatus; // 'available' | 'busy' | 'away'
  final String profileImageUrl;
  final DateTime? dateOfBirth;
  final String phoneNumber;
  final String officeLocation;

  const FacultyModel({
    required this.id,
    required this.email,
    this.firstName = '',
    this.lastName = '',
    this.departmentId = '',
    this.availabilityStatus = 'away',
    this.profileImageUrl = '',
    this.dateOfBirth,
    this.phoneNumber = '',
    this.officeLocation = '',
  });

  /// Convenience getter — full display name.
  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isNotEmpty ? full : email;
  }

  /// Create from Firestore document snapshot.
  factory FacultyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FacultyModel(
      id: doc.id,
      email: data['email'] ?? '',
      firstName: data['first_name'] ?? '',
      lastName: data['last_name'] ?? '',
      departmentId: data['department_id'] ?? '',
      availabilityStatus: data['availability_status'] ?? 'away',
      profileImageUrl: (data['profile_image_url'] as String? ?? '').replaceAll(RegExp(r'\s+'), ''),
      dateOfBirth: (data['date_of_birth'] as Timestamp?)?.toDate(),
      phoneNumber: data['phone_number'] ?? '',
      officeLocation: data['office_location'] ?? '',
    );
  }

  /// Convert to Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'department_id': departmentId,
      'availability_status': availabilityStatus,
      'profile_image_url': profileImageUrl,
      'date_of_birth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'phone_number': phoneNumber,
      'office_location': officeLocation,
    };
  }

  /// Create a copy with updated fields.
  FacultyModel copyWith({
    String? firstName,
    String? lastName,
    String? departmentId,
    String? availabilityStatus,
    String? profileImageUrl,
    DateTime? dateOfBirth,
    String? phoneNumber,
    String? officeLocation,
  }) {
    return FacultyModel(
      id: id,
      email: email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      departmentId: departmentId ?? this.departmentId,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      officeLocation: officeLocation ?? this.officeLocation,
    );
  }
}
