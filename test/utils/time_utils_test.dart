import 'package:flutter_test/flutter_test.dart';
import 'package:juciflut/utils/time_utils.dart';

void main() {
  group('TimeUtils', () {
    group('parseTimeToMinutes', () {
      test('should parse AM times correctly', () {
        expect(TimeUtils.parseTimeToMinutes('8:00 AM'), 480);
        expect(TimeUtils.parseTimeToMinutes('9:30 AM'), 570);
        expect(TimeUtils.parseTimeToMinutes('12:00 AM'), 0); // Midnight
        expect(TimeUtils.parseTimeToMinutes('1:00 AM'), 60);
      });

      test('should parse PM times correctly', () {
        expect(TimeUtils.parseTimeToMinutes('12:00 PM'), 720); // Noon
        expect(TimeUtils.parseTimeToMinutes('1:00 PM'), 780);
        expect(TimeUtils.parseTimeToMinutes('2:30 PM'), 870);
        expect(TimeUtils.parseTimeToMinutes('11:45 PM'), 1425);
      });

      test('should handle whitespace', () {
        expect(TimeUtils.parseTimeToMinutes('  8:00 AM  '), 480);
        expect(TimeUtils.parseTimeToMinutes('  2:30 PM  '), 870);
      });

      test('should throw on invalid format', () {
        expect(
          () => TimeUtils.parseTimeToMinutes('25:00 AM'),
          throwsFormatException,
        );
        expect(
          () => TimeUtils.parseTimeToMinutes('8:60 AM'),
          throwsFormatException,
        );
        expect(
          () => TimeUtils.parseTimeToMinutes('invalid'),
          throwsFormatException,
        );
      });
    });

    group('doTimeRangesOverlap', () {
      test('should detect exact overlap', () {
        expect(
          TimeUtils.doTimeRangesOverlap(
            start1: '9:00 AM',
            end1: '11:00 AM',
            start2: '9:00 AM',
            end2: '11:00 AM',
          ),
          true,
        );
      });

      test('should detect partial overlap', () {
        // Range 1 starts before range 2 ends
        expect(
          TimeUtils.doTimeRangesOverlap(
            start1: '9:00 AM',
            end1: '11:00 AM',
            start2: '10:00 AM',
            end2: '12:00 PM',
          ),
          true,
        );

        // Range 2 starts before range 1 ends
        expect(
          TimeUtils.doTimeRangesOverlap(
            start1: '10:00 AM',
            end1: '12:00 PM',
            start2: '9:00 AM',
            end2: '11:00 AM',
          ),
          true,
        );
      });

      test('should allow back-to-back slots (no overlap)', () {
        expect(
          TimeUtils.doTimeRangesOverlap(
            start1: '9:00 AM',
            end1: '10:00 AM',
            start2: '10:00 AM',
            end2: '11:00 AM',
          ),
          false, // Back-to-back is allowed
        );

        expect(
          TimeUtils.doTimeRangesOverlap(
            start1: '10:00 AM',
            end1: '11:00 AM',
            start2: '9:00 AM',
            end2: '10:00 AM',
          ),
          false, // Back-to-back is allowed
        );
      });

      test('should detect no overlap when completely separate', () {
        expect(
          TimeUtils.doTimeRangesOverlap(
            start1: '8:00 AM',
            end1: '9:00 AM',
            start2: '10:00 AM',
            end2: '11:00 AM',
          ),
          false,
        );

        expect(
          TimeUtils.doTimeRangesOverlap(
            start1: '10:00 AM',
            end1: '11:00 AM',
            start2: '8:00 AM',
            end2: '9:00 AM',
          ),
          false,
        );
      });

      test('should detect range inside another', () {
        expect(
          TimeUtils.doTimeRangesOverlap(
            start1: '9:00 AM',
            end1: '12:00 PM',
            start2: '10:00 AM',
            end2: '11:00 AM',
          ),
          true, // Range 2 completely inside range 1
        );

        expect(
          TimeUtils.doTimeRangesOverlap(
            start1: '10:00 AM',
            end1: '11:00 AM',
            start2: '9:00 AM',
            end2: '12:00 PM',
          ),
          true, // Range 1 completely inside range 2
        );
      });

      test('should throw on invalid ranges', () {
        expect(
          () => TimeUtils.doTimeRangesOverlap(
            start1: '11:00 AM',
            end1: '9:00 AM', // End before start
            start2: '10:00 AM',
            end2: '12:00 PM',
          ),
          throwsFormatException,
        );
      });
    });

    group('formatMinutesToTime', () {
      test('should format AM times correctly', () {
        expect(TimeUtils.formatMinutesToTime(0), '12:00 AM'); // Midnight
        expect(TimeUtils.formatMinutesToTime(60), '1:00 AM');
        expect(TimeUtils.formatMinutesToTime(480), '8:00 AM');
        expect(TimeUtils.formatMinutesToTime(570), '9:30 AM');
      });

      test('should format PM times correctly', () {
        expect(TimeUtils.formatMinutesToTime(720), '12:00 PM'); // Noon
        expect(TimeUtils.formatMinutesToTime(780), '1:00 PM');
        expect(TimeUtils.formatMinutesToTime(870), '2:30 PM');
        expect(TimeUtils.formatMinutesToTime(1425), '11:45 PM');
      });

      test('should round-trip correctly', () {
        final times = ['8:00 AM', '12:00 PM', '2:30 PM', '11:45 PM'];
        
        for (final time in times) {
          final minutes = TimeUtils.parseTimeToMinutes(time);
          final formatted = TimeUtils.formatMinutesToTime(minutes);
          expect(formatted, time);
        }
      });
    });

    group('getDurationMinutes', () {
      test('should calculate duration correctly', () {
        expect(
          TimeUtils.getDurationMinutes('8:00 AM', '9:00 AM'),
          60,
        );
        expect(
          TimeUtils.getDurationMinutes('9:00 AM', '11:30 AM'),
          150,
        );
        expect(
          TimeUtils.getDurationMinutes('8:00 AM', '12:00 PM'),
          240,
        );
      });
    });

    group('formatDuration', () {
      test('should format minutes only', () {
        expect(TimeUtils.formatDuration(30), '30 minutes');
        expect(TimeUtils.formatDuration(45), '45 minutes');
        expect(TimeUtils.formatDuration(1), '1 minute');
      });

      test('should format hours only', () {
        expect(TimeUtils.formatDuration(60), '1 hour');
        expect(TimeUtils.formatDuration(120), '2 hours');
        expect(TimeUtils.formatDuration(180), '3 hours');
      });

      test('should format hours and minutes', () {
        expect(TimeUtils.formatDuration(90), '1 hour 30 minutes');
        expect(TimeUtils.formatDuration(150), '2 hours 30 minutes');
        expect(TimeUtils.formatDuration(125), '2 hours 5 minutes');
      });
    });

    group('edge cases', () {
      test('should handle midnight to noon', () {
        expect(
          TimeUtils.doTimeRangesOverlap(
            start1: '11:00 PM',
            end1: '11:59 PM',
            start2: '12:00 AM',
            end2: '1:00 AM',
          ),
          false, // Different parts of day
        );
      });

      test('should handle noon times', () {
        expect(TimeUtils.parseTimeToMinutes('12:00 PM'), 720);
        expect(TimeUtils.parseTimeToMinutes('12:30 PM'), 750);
      });

      test('should handle complex overlaps', () {
        // Morning class 8-10, consultation 9-11
        expect(
          TimeUtils.doTimeRangesOverlap(
            start1: '8:00 AM',
            end1: '10:00 AM',
            start2: '9:00 AM',
            end2: '11:00 AM',
          ),
          true,
        );

        // Afternoon meeting 1-3, class 2-4
        expect(
          TimeUtils.doTimeRangesOverlap(
            start1: '1:00 PM',
            end1: '3:00 PM',
            start2: '2:00 PM',
            end2: '4:00 PM',
          ),
          true,
        );
      });
    });
  });
}
