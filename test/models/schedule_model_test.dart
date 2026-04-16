import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:juciflut/models/schedule_model.dart';

void main() {
  group('ScheduleModel', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    group('fromFirestore', () {
      test('should create ScheduleModel from Firestore document', () async {
        // Arrange
        final now = DateTime.now();
        final docData = {
          'faculty_id': 'faculty-123',
          'day': 'Monday',
          'time_start': '8:00 AM',
          'time_end': '9:00 AM',
          'type': 'consultation',
          'title': 'Office Hours',
          'location': 'Room 201',
          'is_booked': false,
          'createdAt': Timestamp.fromDate(now),
        };

        final docRef = await fakeFirestore.collection('schedules').add(docData);
        final snapshot = await docRef.get();

        // Act
        final schedule = ScheduleModel.fromFirestore(snapshot);

        // Assert
        expect(schedule.id, snapshot.id);
        expect(schedule.facultyId, 'faculty-123');
        expect(schedule.day, 'Monday');
        expect(schedule.timeStart, '8:00 AM');
        expect(schedule.timeEnd, '9:00 AM');
        expect(schedule.type, 'consultation');
        expect(schedule.title, 'Office Hours');
        expect(schedule.location, 'Room 201');
        expect(schedule.isBooked, false);
        expect(schedule.createdAt, isNotNull);
      });

      test('should handle booked schedule', () async {
        // Arrange
        final docData = {
          'faculty_id': 'faculty-123',
          'day': 'Tuesday',
          'time_start': '10:00 AM',
          'time_end': '11:00 AM',
          'type': 'consultation',
          'title': 'Student Consultation',
          'location': 'Room 301',
          'is_booked': true,
          'createdAt': Timestamp.now(),
        };

        final docRef = await fakeFirestore.collection('schedules').add(docData);
        final snapshot = await docRef.get();

        // Act
        final schedule = ScheduleModel.fromFirestore(snapshot);

        // Assert
        expect(schedule.isBooked, true);
      });

      test('should handle minimal data with defaults', () async {
        // Arrange
        final docData = {
          'faculty_id': 'faculty-123',
          'day': 'Wednesday',
          'time_start': '1:00 PM',
          'time_end': '2:00 PM',
          'type': 'class',
        };

        final docRef = await fakeFirestore.collection('schedules').add(docData);
        final snapshot = await docRef.get();

        // Act
        final schedule = ScheduleModel.fromFirestore(snapshot);

        // Assert
        expect(schedule.facultyId, 'faculty-123');
        expect(schedule.day, 'Wednesday');
        expect(schedule.type, 'class');
        expect(schedule.title, ''); // Default
        expect(schedule.location, ''); // Default
        expect(schedule.isBooked, false); // Default
      });

      test('should handle camelCase field names (backwards compatibility)', () async {
        // Arrange - using camelCase instead of snake_case
        final docData = {
          'facultyId': 'faculty-123',
          'day': 'Thursday',
          'timeStart': '3:00 PM',
          'timeEnd': '4:00 PM',
          'type': 'meeting',
          'isBooked': true,
        };

        final docRef = await fakeFirestore.collection('schedules').add(docData);
        final snapshot = await docRef.get();

        // Act
        final schedule = ScheduleModel.fromFirestore(snapshot);

        // Assert
        expect(schedule.facultyId, 'faculty-123');
        expect(schedule.timeStart, '3:00 PM');
        expect(schedule.timeEnd, '4:00 PM');
        expect(schedule.isBooked, true);
      });
    });

    group('toFirestore', () {
      test('should convert ScheduleModel to Firestore-compatible map', () {
        // Arrange
        final now = DateTime.now();
        final schedule = ScheduleModel(
          id: 'test-id',
          facultyId: 'faculty-123',
          day: 'Friday',
          timeStart: '8:00 AM',
          timeEnd: '9:00 AM',
          type: 'consultation',
          title: 'Office Hours',
          location: 'Room 201',
          isBooked: false,
          createdAt: now,
        );

        // Act
        final firestoreData = schedule.toFirestore();

        // Assert
        expect(firestoreData['faculty_id'], 'faculty-123');
        expect(firestoreData['day'], 'Friday');
        expect(firestoreData['time_start'], '8:00 AM');
        expect(firestoreData['time_end'], '9:00 AM');
        expect(firestoreData['type'], 'consultation');
        expect(firestoreData['title'], 'Office Hours');
        expect(firestoreData['location'], 'Room 201');
        expect(firestoreData['is_booked'], false);
        expect(firestoreData['createdAt'], isA<Timestamp>());
        expect(firestoreData.containsKey('id'), false); // ID not included
      });

      test('should use current timestamp if createdAt is null', () {
        // Arrange
        final schedule = ScheduleModel(
          id: 'test-id',
          facultyId: 'faculty-123',
          day: 'Monday',
          timeStart: '10:00 AM',
          timeEnd: '11:00 AM',
          type: 'consultation',
          createdAt: null,
        );

        // Act
        final firestoreData = schedule.toFirestore();

        // Assert
        expect(firestoreData['createdAt'], isA<Timestamp>());
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        // Arrange
        final original = ScheduleModel(
          id: 'test-id',
          facultyId: 'faculty-123',
          day: 'Monday',
          timeStart: '8:00 AM',
          timeEnd: '9:00 AM',
          type: 'consultation',
          title: 'Office Hours',
          location: 'Room 201',
          isBooked: false,
        );

        // Act
        final updated = original.copyWith(
          title: 'Updated Office Hours',
          location: 'Room 301',
          isBooked: true,
        );

        // Assert
        expect(updated.id, original.id);
        expect(updated.facultyId, original.facultyId);
        expect(updated.day, original.day);
        expect(updated.timeStart, original.timeStart);
        expect(updated.timeEnd, original.timeEnd);
        expect(updated.type, original.type);
        expect(updated.title, 'Updated Office Hours'); // Updated
        expect(updated.location, 'Room 301'); // Updated
        expect(updated.isBooked, true); // Updated
      });

      test('should keep original values when no updates', () {
        // Arrange
        final original = ScheduleModel(
          id: 'test-id',
          facultyId: 'faculty-123',
          day: 'Tuesday',
          timeStart: '1:00 PM',
          timeEnd: '2:00 PM',
          type: 'meeting',
        );

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy.id, original.id);
        expect(copy.facultyId, original.facultyId);
        expect(copy.day, original.day);
        expect(copy.timeStart, original.timeStart);
        expect(copy.timeEnd, original.timeEnd);
        expect(copy.type, original.type);
      });
    });

    group('timeRange getter', () {
      test('should return formatted time range', () {
        // Arrange
        final schedule = ScheduleModel(
          id: 'test-id',
          facultyId: 'faculty-123',
          day: 'Monday',
          timeStart: '8:00 AM',
          timeEnd: '9:00 AM',
          type: 'consultation',
        );

        // Act & Assert
        expect(schedule.timeRange, '8:00 AM – 9:00 AM');
      });

      test('should handle different time formats', () {
        // Arrange
        final schedule = ScheduleModel(
          id: 'test-id',
          facultyId: 'faculty-123',
          day: 'Friday',
          timeStart: '1:30 PM',
          timeEnd: '3:00 PM',
          type: 'class',
        );

        // Act & Assert
        expect(schedule.timeRange, '1:30 PM – 3:00 PM');
      });
    });

    group('edge cases', () {
      test('should handle empty strings', () async {
        // Arrange
        final docData = {
          'faculty_id': '',
          'day': '',
          'time_start': '',
          'time_end': '',
          'type': '',
        };

        final docRef = await fakeFirestore.collection('schedules').add(docData);
        final snapshot = await docRef.get();

        // Act
        final schedule = ScheduleModel.fromFirestore(snapshot);

        // Assert
        expect(schedule.facultyId, '');
        expect(schedule.day, '');
        expect(schedule.timeStart, '');
        expect(schedule.timeEnd, '');
      });

      test('should maintain const constructor properties', () {
        // Arrange & Act
        const schedule1 = ScheduleModel(
          id: 'test-id',
          facultyId: 'faculty-123',
          day: 'Monday',
          timeStart: '8:00 AM',
          timeEnd: '9:00 AM',
        );

        const schedule2 = ScheduleModel(
          id: 'test-id',
          facultyId: 'faculty-123',
          day: 'Monday',
          timeStart: '8:00 AM',
          timeEnd: '9:00 AM',
        );

        // Assert - identical objects
        expect(identical(schedule1, schedule2), true);
      });
    });
  });
}
