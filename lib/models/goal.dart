import 'package:cloud_firestore/cloud_firestore.dart';

class Goal {
  final String goalId;
  final String facilityId;
  final String title;
  final String description;
  final String category;
  final String icon;
  final String color;
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  Goal({
    required this.goalId,
    required this.facilityId,
    required this.title,
    required this.description,
    required this.category,
    this.icon = 'star',
    this.color = 'green',
    this.isActive = true,
    this.displayOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'goal_id': goalId,
        'facility_id': facilityId,
        'title': title,
        'description': description,
        'category': category,
        'icon': icon,
        'color': color,
        'is_active': isActive,
        'display_order': displayOrder,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Goal.fromMap(Map<String, dynamic> map) => Goal(
        goalId: map['goal_id'] as String,
        facilityId: map['facility_id'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        category: map['category'] as String,
        icon: map['icon'] as String? ?? 'star',
        color: map['color'] as String? ?? 'green',
        isActive: map['is_active'] as bool? ?? true,
        displayOrder: map['display_order'] as int? ?? 0,
        createdAt: _parseDateTime(map['created_at']),
        updatedAt: _parseDateTime(map['updated_at']),
      );

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  Goal copyWith({
    String? title,
    String? description,
    String? category,
    String? icon,
    String? color,
    bool? isActive,
    int? displayOrder,
    DateTime? updatedAt,
  }) =>
      Goal(
        goalId: goalId,
        facilityId: facilityId,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        isActive: isActive ?? this.isActive,
        displayOrder: displayOrder ?? this.displayOrder,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );
}
