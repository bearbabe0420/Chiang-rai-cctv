class DetectionEvent {
  final String cameraId;
  final DateTime lastDetection;
  final int todayCount;
  final String? snapshotUrl;

  const DetectionEvent({
    required this.cameraId,
    required this.lastDetection,
    required this.todayCount,
    this.snapshotUrl,
  });

  String get formattedTime {
    final h = lastDetection.hour;
    final m = lastDetection.minute.toString().padLeft(2, '0');
    final s = lastDetection.second.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '${hour12.toString().padLeft(2, '0')}:$m:$s $period';
  }
}

class LicensePlateData {
  final int totalDetected;
  const LicensePlateData({required this.totalDetected});

  String get formattedTotal {
    return totalDetected.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}

class SystemStats {
  final int camerasOnline;
  final int alertsToday;
  final double systemUptimePercent;
  final double storageUsedPercent;

  const SystemStats({
    required this.camerasOnline,
    required this.alertsToday,
    required this.systemUptimePercent,
    required this.storageUsedPercent,
  });

  String get formattedUptime => '${systemUptimePercent.toStringAsFixed(1)}%';
  String get formattedStorage => '${storageUsedPercent.toStringAsFixed(0)}%';
}