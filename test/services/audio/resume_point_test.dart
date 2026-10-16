import 'package:codecore/services/audio/resume_point.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const long = 3 * 60 * 60 * 1000; // 3 h

  group('resumePointFor', () {
    test('a long track in the middle is remembered as is', () {
      expect(resumePointFor(const Duration(minutes: 42, seconds: 10), long),
          const Duration(minutes: 42, seconds: 10).inMilliseconds);
    });

    test('short tracks never get a bookmark', () {
      expect(resumePointFor(const Duration(minutes: 2), 4 * 60 * 1000), isNull);
      // 19:59 is still short, 20:00 is long.
      expect(resumePointFor(const Duration(minutes: 10), 19 * 60 * 1000 + 59000), isNull);
      expect(resumePointFor(const Duration(minutes: 10), 20 * 60 * 1000), isNotNull);
    });

    test('the first and last 30 seconds clear it', () {
      expect(resumePointFor(const Duration(seconds: 29), long), isNull);
      expect(resumePointFor(const Duration(seconds: 30), long), 30000);
      final end = Duration(milliseconds: long);
      expect(resumePointFor(end - const Duration(seconds: 31), long), isNotNull);
      expect(resumePointFor(end - const Duration(seconds: 29), long), isNull);
      expect(resumePointFor(end, long), isNull);
    });

    test('unknown length never gets one', () {
      expect(resumePointFor(const Duration(minutes: 30), 0), isNull);
    });
  });

  group('resumeStartFor', () {
    test('starts 5 seconds before the saved point', () {
      expect(resumeStartFor(600000), const Duration(minutes: 9, seconds: 55));
    });

    test('never before the start; nothing saved means no start', () {
      expect(resumeStartFor(3000), Duration.zero);
      expect(resumeStartFor(null), isNull);
      expect(resumeStartFor(0), isNull);
    });
  });
}
