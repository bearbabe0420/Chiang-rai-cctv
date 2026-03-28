class AccidentDashboardModel {
  final AccidentLatest? latestAccident;
  final List<AccidentTopCamera> topCameras;

  const AccidentDashboardModel({
    this.latestAccident,
    this.topCameras = const [],
  });

  factory AccidentDashboardModel.fromJson(Map<String, dynamic> json) {
    final topCameraList = json['top_cameras'];
    return AccidentDashboardModel(
      latestAccident: json['latest_accident'] is Map<String, dynamic>
          ? AccidentLatest.fromJson(
              json['latest_accident'] as Map<String, dynamic>)
          : json['latest_accident'] is Map
              ? AccidentLatest.fromJson(
                  Map<String, dynamic>.from(json['latest_accident'] as Map),
                )
              : null,
      topCameras: topCameraList is List
          ? topCameraList
              .whereType<Map>()
              .map((camera) =>
                  AccidentTopCamera.fromJson(Map<String, dynamic>.from(camera)))
              .toList()
          : const [],
    );
  }
}

class AccidentLatest {
  final String? id;
  final String? timestamp;
  final String? imageUrl;
  final String? cameraId;
  final String? cameraName;
  final String? cameraAddress;

  const AccidentLatest({
    this.id,
    this.timestamp,
    this.imageUrl,
    this.cameraId,
    this.cameraName,
    this.cameraAddress,
  });

  factory AccidentLatest.fromJson(Map<String, dynamic> json) {
    return AccidentLatest(
      id: json['id'] as String?,
      timestamp: json['timestamp'] as String?,
      imageUrl: json['image_url'] as String?,
      cameraId: json['camera_id'] as String?,
      cameraName: json['camera_name'] as String?,
      cameraAddress: json['camera_address'] as String?,
    );
  }
}

class AccidentTopCamera {
  final String? cameraId;
  final String? cameraName;
  final String? cameraAddress;
  final int? accidentCount;

  const AccidentTopCamera({
    this.cameraId,
    this.cameraName,
    this.cameraAddress,
    this.accidentCount,
  });

  factory AccidentTopCamera.fromJson(Map<String, dynamic> json) {
    final count = json['accident_count'];
    return AccidentTopCamera(
      cameraId: json['camera_id'] as String?,
      cameraName: json['camera_name'] as String?,
      cameraAddress: json['camera_address'] as String?,
      accidentCount: count is int ? count : int.tryParse('${count ?? ''}'),
    );
  }
}
