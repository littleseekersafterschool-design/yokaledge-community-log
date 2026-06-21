class Staff {
  final String staffId;
  final String facilityId;
  final String staffName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Staff({
    required this.staffId,
    required this.facilityId,
    required this.staffName,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'staff_id': staffId,
        'facility_id': facilityId,
        'staff_name': staffName,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Staff.fromMap(Map<String, dynamic> map) => Staff(
        staffId: map['staff_id'] as String,
        facilityId: map['facility_id'] as String,
        staffName: map['staff_name'] as String,
        isActive: map['is_active'] as bool? ?? true,
        createdAt: _parseDateTime(map['created_at']),
        updatedAt: _parseDateTime(map['updated_at']),
      );

  static DateTime _parseDateTime(dynamic value) {
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  Staff copyWith({
    String? staffName,
    bool? isActive,
    DateTime? updatedAt,
  }) =>
      Staff(
        staffId: staffId,
        facilityId: facilityId,
        staffName: staffName ?? this.staffName,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );
}
