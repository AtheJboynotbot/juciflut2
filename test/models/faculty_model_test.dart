import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:juciflut/models/faculty_model.dart';

void main() {
  group('FacultyModel', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    group('fromFirestore', () {
      test('should create FacultyModel from Firestore document', () async {
        // Arrange
        final docData = {
          'email': 'test@addu.edu.ph',
          'first_name': 'John',
          'last_name': 'Doe',
          'department_id': 'CS',
          'availability_status': 'available',
          'profile_image_url': 'https://example.com/image.png',
          'phone_number': '+63 123 456 7890',
          'office_location': 'Room 201',
          'date_of_birth': Timestamp.fromDate(DateTime(1990, 1, 1)),
        };

        final docRef = await fakeFirestore.collection('faculty').add(docData);
        final snapshot = await docRef.get();

        // Act
        final faculty = FacultyModel.fromFirestore(snapshot);

        // Assert
        expect(faculty.id, snapshot.id);
        expect(faculty.email, 'test@addu.edu.ph');
        expect(faculty.firstName, 'John');
        expect(faculty.lastName, 'Doe');
        expect(faculty.departmentId, 'CS');
        expect(faculty.availabilityStatus, 'available');
        expect(faculty.profileImageUrl, 'https://example.com/image.png');
        expect(faculty.phoneNumber, '+63 123 456 7890');
        expect(faculty.officeLocation, 'Room 201');
        expect(faculty.dateOfBirth, DateTime(1990, 1, 1));
      });

      test('should handle minimal data with defaults', () async {
        // Arrange
        final docData = {
          'email': 'test@addu.edu.ph',
          'first_name': 'John',
          'last_name': 'Doe',
        };

        final docRef = await fakeFirestore.collection('faculty').add(docData);
        final snapshot = await docRef.get();

        // Act
        final faculty = FacultyModel.fromFirestore(snapshot);

        // Assert
        expect(faculty.email, 'test@addu.edu.ph');
        expect(faculty.firstName, 'John');
        expect(faculty.lastName, 'Doe');
        expect(faculty.departmentId, '');
        expect(faculty.availabilityStatus, 'away'); // Default is 'away'
        expect(faculty.profileImageUrl, '');
        expect(faculty.phoneNumber, '');
        expect(faculty.officeLocation, '');
        expect(faculty.dateOfBirth, null);
      });

      test('should handle URL with whitespace', () async {
        // Arrange - simulating corrupted URL
        final docData = {
          'email': 'test@addu.edu.ph',
          'first_name': 'John',
          'last_name': 'Doe',
          'profile_image_url': 'https://example.com/image.png\n ',
        };

        final docRef = await fakeFirestore.collection('faculty').add(docData);
        final snapshot = await docRef.get();

        // Act
        final faculty = FacultyModel.fromFirestore(snapshot);

        // Assert - URL should be cleaned
        expect(faculty.profileImageUrl, 'https://example.com/image.png');
      });
    });

    group('toFirestore', () {
      test('should convert FacultyModel to Firestore-compatible map', () {
        // Arrange
        final faculty = FacultyModel(
          id: 'test-id',
          email: 'test@addu.edu.ph',
          firstName: 'John',
          lastName: 'Doe',
          departmentId: 'CS',
          availabilityStatus: 'busy',
          profileImageUrl: 'https://example.com/image.png',
          phoneNumber: '+63 123 456 7890',
          officeLocation: 'Room 201',
          dateOfBirth: DateTime(1990, 1, 1),
        );

        // Act
        final firestoreData = faculty.toFirestore();

        // Assert
        expect(firestoreData['email'], 'test@addu.edu.ph');
        expect(firestoreData['first_name'], 'John');
        expect(firestoreData['last_name'], 'Doe');
        expect(firestoreData['department_id'], 'CS');
        expect(firestoreData['availability_status'], 'busy');
        expect(firestoreData['profile_image_url'], 'https://example.com/image.png');
        expect(firestoreData['phone_number'], '+63 123 456 7890');
        expect(firestoreData['office_location'], 'Room 201');
        expect(firestoreData['date_of_birth'], isA<Timestamp>());
        expect(firestoreData.containsKey('id'), false); // ID not included
      });

      test('should handle empty optional fields', () {
        // Arrange
        final faculty = FacultyModel(
          id: 'test-id',
          email: 'test@addu.edu.ph',
          firstName: 'John',
          lastName: 'Doe',
        );

        // Act
        final firestoreData = faculty.toFirestore();

        // Assert
        expect(firestoreData['email'], 'test@addu.edu.ph');
        expect(firestoreData['first_name'], 'John');
        expect(firestoreData['last_name'], 'Doe');
        expect(firestoreData['department_id'], '');
        expect(firestoreData['availability_status'], 'away'); // Default is 'away'
        expect(firestoreData['profile_image_url'], '');
      });
    });

    group('computed properties', () {
      test('displayName should return firstName + lastName', () {
        // Arrange
        final faculty = FacultyModel(
          id: 'test-id',
          email: 'test@addu.edu.ph',
          firstName: 'John',
          lastName: 'Doe',
        );

        // Act & Assert
        expect(faculty.displayName, 'John Doe');
      });

      test('displayName should return email when name is empty', () {
        // Arrange
        final faculty = FacultyModel(
          id: 'test-id',
          email: 'test@addu.edu.ph',
          firstName: '',
          lastName: '',
        );

        // Act & Assert
        expect(faculty.displayName, 'test@addu.edu.ph');
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        // Arrange
        final original = FacultyModel(
          id: 'test-id',
          email: 'test@addu.edu.ph',
          firstName: 'John',
          lastName: 'Doe',
          availabilityStatus: 'available',
        );

        // Act
        final updated = original.copyWith(
          availabilityStatus: 'busy',
          phoneNumber: '+63 123 456 7890',
        );

        // Assert
        expect(updated.id, original.id);
        expect(updated.email, original.email);
        expect(updated.firstName, original.firstName);
        expect(updated.lastName, original.lastName);
        expect(updated.availabilityStatus, 'busy'); // Updated
        expect(updated.phoneNumber, '+63 123 456 7890'); // Updated
      });

      test('should keep original values when no updates', () {
        // Arrange
        final original = FacultyModel(
          id: 'test-id',
          email: 'test@addu.edu.ph',
          firstName: 'John',
          lastName: 'Doe',
        );

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy.id, original.id);
        expect(copy.email, original.email);
        expect(copy.firstName, original.firstName);
        expect(copy.lastName, original.lastName);
      });
    });
  });
}
