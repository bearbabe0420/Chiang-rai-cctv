import 'package:flutter_test/flutter_test.dart';
import 'package:central_command/utils/time_ago_formatter.dart';

void main() {
  group('TimeAgoFormatter.format', () {
    test('returns ล่าสุด for less than 60 seconds', () {
      final ts = DateTime.now().subtract(const Duration(seconds: 30));

      final result = TimeAgoFormatter.format(ts);

      expect(result, 'ล่าสุด');
    });

    test('returns minute text for less than 60 minutes', () {
      final ts = DateTime.now().subtract(const Duration(minutes: 5));

      final result = TimeAgoFormatter.format(ts);

      expect(result, '5 นาทีที่แล้ว');
    });

    test('returns hour text for less than 24 hours', () {
      final ts = DateTime.now().subtract(const Duration(hours: 2));

      final result = TimeAgoFormatter.format(ts);

      expect(result, '2 ชั่วโมงที่แล้ว');
    });

    test('returns day text for up to 30 days', () {
      final ts = DateTime.now().subtract(const Duration(days: 10));

      final result = TimeAgoFormatter.format(ts);

      expect(result, '10 วันที่แล้ว');
    });

    test('returns month text after 30 days', () {
      final ts = DateTime.now().subtract(const Duration(days: 40));

      final result = TimeAgoFormatter.format(ts);

      expect(result, '1 เดือนที่แล้ว');
    });

    test('returns year text for long durations', () {
      final ts = DateTime.now().subtract(const Duration(days: 370));

      final result = TimeAgoFormatter.format(ts);

      expect(result, '1 ปีที่แล้ว');
    });
  });
}
