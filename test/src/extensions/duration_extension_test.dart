import 'package:awesome_task_manager/src/extensions/duration_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('twoDigits tests', () {
    test('Should add leading zero for single digit numbers', () {
      expect(HumanDuration.twoDigits(0), equals('00'));
      expect(HumanDuration.twoDigits(5), equals('05'));
    });

    test('Should not add leading zero for double digit numbers', () {
      expect(HumanDuration.twoDigits(10), equals('10'));
      expect(HumanDuration.twoDigits(99), equals('99'));
    });
  });

  group('threeDigits tests', () {
    test('Should add leading zeros for single digit numbers', () {
      expect(HumanDuration.threeDigits(0), equals('000'));
      expect(HumanDuration.threeDigits(5), equals('005'));
    });

    test('Should add a single leading zero for double digit numbers', () {
      expect(HumanDuration.threeDigits(10), equals('010'));
      expect(HumanDuration.threeDigits(99), equals('099'));
    });

    test('Should not add leading zeros for triple digit numbers', () {
      expect(HumanDuration.threeDigits(1), equals('001'));
      expect(HumanDuration.threeDigits(10), equals('010'));
      expect(HumanDuration.threeDigits(100), equals('100'));
      expect(HumanDuration.threeDigits(999), equals('999'));
    });
  });

  group('HumanDuration tests', () {
    test('Should display only milliseconds', () {
      Duration duration = const Duration(milliseconds: 150);
      expect(duration.humanString, equals('150 ms'));
    });

    test('Should display only seconds', () {
      Duration duration = const Duration(seconds: 20);
      expect(duration.humanString, equals('20.000 sec'));
    });

    test('Should display seconds and milliseconds', () {
      Duration duration = const Duration(seconds: 20, milliseconds: 150);
      expect(duration.humanString, equals('20.150 sec'));
    });

    test('Should display only minutes', () {
      Duration duration = const Duration(minutes: 3);
      expect(duration.humanString, equals('03:00.000 min'));
    });

    test('Should display minutes and seconds', () {
      Duration duration = const Duration(minutes: 3, seconds: 20);
      expect(duration.humanString, equals('03:20.000 min'));
    });

    test('Should display minutes, seconds, and milliseconds', () {
      Duration duration =
          const Duration(minutes: 3, seconds: 20, milliseconds: 150);
      expect(duration.humanString, equals('03:20.150 min'));
    });

    // Adding a test case for hours, which should be converted to minutes
    test('Should handle hours correctly', () {
      Duration duration =
          const Duration(hours: 1, minutes: 3, seconds: 20, milliseconds: 150);
      expect(duration.humanString, equals('63:20.150 min'));
    });
  });
}
