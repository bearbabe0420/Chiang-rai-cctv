import 'package:intl/intl.dart';

class TimeAgoFormatter {
  static String format(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return "ล่าสุด";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes} นาทีที่แล้ว";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} ชั่วโมงที่แล้ว";
    } else if (difference.inDays <= 30) {
      return "${difference.inDays} วันที่แล้ว";
    } else {
      // For periods longer than 30 days, you might want a more specific format
      // This is a simple approximation.
      final months = (difference.inDays / 30).floor();
      if (months < 12) {
        return "$months เดือนที่แล้ว";
      } else {
        final years = (months / 12).floor();
        return "$years ปีที่แล้ว";
      }
    }
  }
}
