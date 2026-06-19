import 'package:cloud_firestore/cloud_firestore.dart';

class DailyLog {
  final String logId;
  final String facilityId;
  final String staffId;
  final String goalId;
  final int score;
  final String comment;
  final String logDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyLog({
    required this.logId,
    required this.facilityId,
    required this.staffId,
    required this.goalId,
    required this.score,
    this.comment = '',
    required this.logDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'log_id': logId,
        'facility_id': facilityId,
        'staff_id': staffId,
        'goal_id': goalId,
        'score': score,
        'comment': comment,
        'log_date': logDate,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory DailyLog.fromMap(Map<String, dynamic> map) => DailyLog(
        logId: map['log_id'] as String,
        facilityId: map['facility_id'] as String,
        staffId: map['staff_id'] as String,
        goalId: map['goal_id'] as String,
        score: map['score'] as int,
        comment: map['comment'] as String? ?? '',
        logDate: map['log_date'] as String,
        createdAt: _parseDateTime(map['created_at']),
        updatedAt: _parseDateTime(map['updated_at']),
      );

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  DailyLog copyWith({
    int? score,
    String? comment,
    DateTime? updatedAt,
  }) =>
      DailyLog(
        logId: logId,
        facilityId: facilityId,
        staffId: staffId,
        goalId: goalId,
        score: score ?? this.score,
        comment: comment ?? this.comment,
        logDate: logDate,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  static String scoreLabel(int score) {
    switch (score) {
      case 1:
        return 'できなかった';
      case 2:
        return 'あまりできなかった';
      case 3:
        return 'ふつう';
      case 4:
        return 'できた';
      case 5:
        return 'よくできた';
      default:
        return '';
    }
  }
}
