import 'category_model.dart';

/// Camera Data Model - โมเดลข้อมูลกล้อง
class CameraModel {
  final String? id;
  final String? name;
  final String? latLong;
  final String? address;
  final String? rtspUrl;
  final String? status;
  final DateTime? lastSeen;
  final List<CategoryModel>? categories;

  CameraModel({
    this.id,
    this.name,
    this.latLong,
    this.address,
    this.rtspUrl,
    this.status,
    this.lastSeen,
    this.categories,
  });

  factory CameraModel.fromJson(Map<String, dynamic> json) {
    return CameraModel(
      id: json['id'] as String?,
      name: json['name'] as String?,
      latLong: json['latLong'] as String?,
      address: json['address'] as String?,
      rtspUrl: json['rtspUrl'] as String?,
      status: json['status'] as String?,
      lastSeen: _parseDateTime(json['lastSeen']),
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (latLong != null) 'latLong': latLong,
      if (address != null) 'address': address,
      if (rtspUrl != null) 'rtspUrl': rtspUrl,
      if (status != null) 'status': status,
      if (lastSeen != null) 'lastSeen': lastSeen!.toIso8601String(),
      if (categories != null)
        'categories': categories?.map((e) => e.toJson()).toList(),
    };
  }

  /// สร้าง JSON body สำหรับ create/edit camera
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name ?? '',
      'latLong': latLong ?? '',
      'address': address ?? '',
      'rtspUrl': rtspUrl ?? '',
    };
  }

  CameraModel copyWith({
    String? id,
    String? name,
    String? latLong,
    String? address,
    String? rtspUrl,
    String? status,
    DateTime? lastSeen,
    List<CategoryModel>? categories,
  }) {
    return CameraModel(
      id: id ?? this.id,
      name: name ?? this.name,
      latLong: latLong ?? this.latLong,
      address: address ?? this.address,
      rtspUrl: rtspUrl ?? this.rtspUrl,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      categories: categories ?? this.categories,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) {
      final isMilliseconds = value > 1000000000000;
      final epoch = isMilliseconds ? value : value * 1000;
      return DateTime.fromMillisecondsSinceEpoch(epoch);
    }
    if (value is double) {
      final isMilliseconds = value > 1000000000000;
      final epoch = isMilliseconds ? value.toInt() : (value * 1000).toInt();
      return DateTime.fromMillisecondsSinceEpoch(epoch);
    }
    return null;
  }

  @override
  String toString() =>
      'CameraModel(id: $id, name: $name, status: $status, lastSeen: $lastSeen)';
}
