import 'package:cloud_firestore/cloud_firestore.dart';

class Facility {
  final String facilityId;
  final String facilityName;
  final String sharedPasswordHash;
  final DateTime createdAt;
  final DateTime updatedAt;

  Facility({
    required this.facilityId,
    required this.facilityName,
    required this.sharedPasswordHash,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'facility_id': facilityId,
        'facility_name': facilityName,
        'shared_password_hash': sharedPasswordHash,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Facility.fromMap(Map<String, dynamic> map) => Facility(
        facilityId: map['facility_id'] as String,
        facilityName: map['facility_name'] as String,
        sharedPasswordHash: map['shared_password_hash'] as String,
        createdAt: _parseDateTime(map['created_at']),
        updatedAt: _parseDateTime(map['updated_at']),
      );

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  Facility copyWith({
    String? facilityName,
    String? sharedPasswordHash,
    DateTime? updatedAt,
  }) =>
      Facility(
        facilityId: facilityId,
        facilityName: facilityName ?? this.facilityName,
        sharedPasswordHash: sharedPasswordHash ?? this.sharedPasswordHash,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );
}
