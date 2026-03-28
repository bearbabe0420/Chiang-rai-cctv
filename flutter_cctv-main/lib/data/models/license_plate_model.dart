/// License Plate Data Model - โมเดลข้อมูลทะเบียนรถ
class LicensePlateModel {
  final String? timestamp;
  final String? cameraName;
  final String? cameraId;
  final String? imageUrl;
  final int? totalLicenseToday;
  final LicensePlateDetail? licensePlate;

  LicensePlateModel({
    this.timestamp,
    this.cameraName,
    this.cameraId,
    this.imageUrl,
    this.totalLicenseToday,
    this.licensePlate,
  });

  factory LicensePlateModel.fromJson(Map<String, dynamic> json) {
    return LicensePlateModel(
      timestamp: json['timestamp'] as String?,
      cameraName:
          (json['camera'] as Map<String, dynamic>?)?['cameraName'] as String?,
      cameraId:
          (json['camera'] as Map<String, dynamic>?)?['cameraId'] as String?,
      imageUrl: json['imageUrl'] as String?,
      totalLicenseToday: json['total_license_today'] is int
          ? json['total_license_today'] as int
          : int.tryParse('${json['total_license_today'] ?? ''}'),
      licensePlate: json['licensePlate'] != null
          ? LicensePlateDetail.fromJson(
              json['licensePlate'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (timestamp != null) 'timestamp': timestamp,
      //if (cameraName != null) 'cameraName': cameraName,
      //if (cameraId != null) 'cameraId': cameraId,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (totalLicenseToday != null) 'total_license_today': totalLicenseToday,
      if (licensePlate != null) 'licensePlate': licensePlate?.toJson(),
      if (cameraName != null || cameraId != null)
        'camera': {
          'cameraName': cameraName,
          'cameraId': cameraId,
        },
    };
  }

  @override
  String toString() =>
      'LicensePlateModel(cameraName: $cameraName, cameraId: $cameraId, plate: ${licensePlate?.fullPlate})';
}

/// รายละเอียดของทะเบียนรถ
class LicensePlateDetail {
  final String? fullPlate;
  final String? province;

  LicensePlateDetail({
    this.fullPlate,
    this.province,
  });

  factory LicensePlateDetail.fromJson(Map<String, dynamic> json) {
    return LicensePlateDetail(
      fullPlate: json['fullPlate'] as String?,
      province: json['province'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (fullPlate != null) 'fullPlate': fullPlate,
      if (province != null) 'province': province,
    };
  }
}
