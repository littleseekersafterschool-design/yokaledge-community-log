import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/daily_log.dart';
import '../models/facility.dart';
import '../models/goal.dart';
import '../models/staff.dart';
import '../utils/goal_templates.dart';
import 'app_config.dart';

class DatabaseService {
  final _uuid = const Uuid();

  List<Facility> _facilities = [];
  List<Staff> _staffList = [];
  List<Goal> _goalsList = [];
  List<DailyLog> _logsList = [];

  Future<void> initialize() async {
    await _loadAllData();
  }

  Future<void> _loadAllData() async {
    final data = await _request('bootstrap');
    _facilities = _asList(data['facilities']).map(Facility.fromMap).toList();
    _staffList = _asList(data['staff']).map(Staff.fromMap).toList();
    _goalsList = _asList(data['goals']).map(Goal.fromMap).toList();
    _logsList = _asList(data['daily_logs']).map(DailyLog.fromMap).toList();
  }

  List<Map<String, dynamic>> _asList(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> _request(
    String action, {
    Map<String, dynamic>? body,
  }) async {
    final response = await http.post(
      AppConfig.apiUri('/api/community-log'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'action': action, ...?body}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'データ通信に失敗しました: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('データ通信の応答形式が正しくありません。');
  }

  Future<void> _upsert(
    String table,
    String idColumn,
    Map<String, dynamic> data,
  ) async {
    await _request('upsert', body: {
      'table': table,
      'idColumn': idColumn,
      'data': data,
    });
  }

  Future<void> _delete(String table, String idColumn, String id) async {
    await _request('delete', body: {
      'table': table,
      'idColumn': idColumn,
      'id': id,
    });
  }

  Future<void> refresh() async {
    await _loadAllData();
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  bool verifyPassword(String password, String hash) {
    return _hashPassword(password) == hash;
  }

  List<Facility> getAllFacilities() => _facilities;

  Facility? getFacility(String facilityId) {
    final matches = _facilities.where((f) => f.facilityId == facilityId);
    return matches.isNotEmpty ? matches.first : null;
  }

  Future<Facility> createFacility(String name, String password) async {
    final now = DateTime.now();
    final facility = Facility(
      facilityId: _uuid.v4(),
      facilityName: name,
      sharedPasswordHash: _hashPassword(password),
      createdAt: now,
      updatedAt: now,
    );
    await _upsert('facilities', 'facility_id', facility.toMap());
    _facilities.add(facility);
    return facility;
  }

  List<Staff> getStaffByFacility(String facilityId, {bool activeOnly = true}) {
    return _staffList
        .where((s) => s.facilityId == facilityId && (!activeOnly || s.isActive))
        .toList();
  }

  Future<Staff> addStaff(String facilityId, String name) async {
    final now = DateTime.now();
    final staff = Staff(
      staffId: _uuid.v4(),
      facilityId: facilityId,
      staffName: name,
      createdAt: now,
      updatedAt: now,
    );
    await _upsert('staff', 'staff_id', staff.toMap());
    _staffList.add(staff);
    return staff;
  }

  Future<void> updateStaff(Staff staff) async {
    await _upsert('staff', 'staff_id', staff.toMap());
    _staffList.removeWhere((s) => s.staffId == staff.staffId);
    _staffList.add(staff);
  }

  Future<void> deleteStaff(String staffId) async {
    final logsToDelete = _logsList.where((l) => l.staffId == staffId).toList();
    for (final log in logsToDelete) {
      await _delete('daily_logs', 'log_id', log.logId);
    }
    await _delete('staff', 'staff_id', staffId);
    _logsList.removeWhere((l) => l.staffId == staffId);
    _staffList.removeWhere((s) => s.staffId == staffId);
  }

  List<Goal> getGoalsByFacility(String facilityId, {bool activeOnly = true}) {
    final goals = _goalsList
        .where((g) => g.facilityId == facilityId && (!activeOnly || g.isActive))
        .toList();
    goals.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return goals;
  }

  Future<Goal> addGoal(Goal goal) async {
    await _upsert('goals', 'goal_id', goal.toMap());
    _goalsList.add(goal);
    return goal;
  }

  Future<void> updateGoal(Goal goal) async {
    await _upsert('goals', 'goal_id', goal.toMap());
    _goalsList.removeWhere((g) => g.goalId == goal.goalId);
    _goalsList.add(goal);
  }

  Future<void> deleteGoal(String goalId) async {
    final logsToDelete = _logsList.where((l) => l.goalId == goalId).toList();
    for (final log in logsToDelete) {
      await _delete('daily_logs', 'log_id', log.logId);
    }
    await _delete('goals', 'goal_id', goalId);
    _logsList.removeWhere((l) => l.goalId == goalId);
    _goalsList.removeWhere((g) => g.goalId == goalId);
  }

  Future<void> applyGoalTemplate(String facilityId, String templateName) async {
    final templates = GoalTemplates.getTemplate(templateName);
    final now = DateTime.now();
    for (var i = 0; i < templates.length; i++) {
      final tmpl = templates[i];
      final goal = Goal(
        goalId: _uuid.v4(),
        facilityId: facilityId,
        title: tmpl.title,
        description: tmpl.description,
        category: tmpl.category,
        icon: tmpl.icon,
        color: tmpl.color,
        displayOrder: i,
        createdAt: now,
        updatedAt: now,
      );
      await addGoal(goal);
    }
  }

  List<DailyLog> getLogsByFacility(String facilityId) {
    return _logsList.where((l) => l.facilityId == facilityId).toList();
  }

  List<DailyLog> getLogsByStaff(String staffId) {
    final logs = _logsList.where((l) => l.staffId == staffId).toList();
    logs.sort((a, b) => b.logDate.compareTo(a.logDate));
    return logs;
  }

  List<DailyLog> getLogsByDate(String facilityId, String date) {
    return _logsList
        .where((l) => l.facilityId == facilityId && l.logDate == date)
        .toList();
  }

  List<DailyLog> getLogsByMonth(String facilityId, int year, int month) {
    final prefix = '$year-${month.toString().padLeft(2, '0')}';
    return _logsList
        .where((l) => l.facilityId == facilityId && l.logDate.startsWith(prefix))
        .toList();
  }

  Future<DailyLog> saveLog(DailyLog log) async {
    final existing = _logsList.where(
      (l) =>
          l.facilityId == log.facilityId &&
          l.staffId == log.staffId &&
          l.goalId == log.goalId &&
          l.logDate == log.logDate,
    );

    if (existing.isNotEmpty) {
      final updated = existing.first.copyWith(
        score: log.score,
        comment: log.comment,
        updatedAt: DateTime.now(),
      );
      await _upsert('daily_logs', 'log_id', updated.toMap());
      _logsList.removeWhere((l) => l.logId == updated.logId);
      _logsList.add(updated);
      return updated;
    }

    await _upsert('daily_logs', 'log_id', log.toMap());
    _logsList.add(log);
    return log;
  }

  Future<void> deleteLog(String logId) async {
    await _delete('daily_logs', 'log_id', logId);
    _logsList.removeWhere((l) => l.logId == logId);
  }

  Future<void> deleteFacility(String facilityId) async {
    final logsToDelete =
        _logsList.where((l) => l.facilityId == facilityId).toList();
    for (final log in logsToDelete) {
      await _delete('daily_logs', 'log_id', log.logId);
    }

    final goalsToDelete =
        _goalsList.where((g) => g.facilityId == facilityId).toList();
    for (final goal in goalsToDelete) {
      await _delete('goals', 'goal_id', goal.goalId);
    }

    final staffToDelete =
        _staffList.where((s) => s.facilityId == facilityId).toList();
    for (final staff in staffToDelete) {
      await _delete('staff', 'staff_id', staff.staffId);
    }

    await _delete('facilities', 'facility_id', facilityId);
    _facilities.removeWhere((f) => f.facilityId == facilityId);
    _staffList.removeWhere((s) => s.facilityId == facilityId);
    _goalsList.removeWhere((g) => g.facilityId == facilityId);
    _logsList.removeWhere((l) => l.facilityId == facilityId);
  }

  String? getLatestLogDate(String facilityId) {
    final logs = getLogsByFacility(facilityId);
    if (logs.isEmpty) return null;
    logs.sort((a, b) => b.logDate.compareTo(a.logDate));
    return logs.first.logDate;
  }

  double getAverageScore(List<DailyLog> logs) {
    if (logs.isEmpty) return 0;
    final total = logs.fold<int>(0, (acc, log) => acc + log.score);
    return total / logs.length;
  }

  Map<String, double> getAverageByGoal(List<DailyLog> logs) {
    final grouped = <String, List<int>>{};
    for (final log in logs) {
      grouped.putIfAbsent(log.goalId, () => []).add(log.score);
    }
    return grouped.map(
      (k, v) => MapEntry(k, v.fold<int>(0, (s, e) => s + e) / v.length),
    );
  }

  List<DailyLog> getRecentComments(String facilityId, {int limit = 20}) {
    final logs = getLogsByFacility(facilityId)
        .where((l) => l.comment.isNotEmpty)
        .toList();
    logs.sort((a, b) {
      final dateComp = b.logDate.compareTo(a.logDate);
      if (dateComp != 0) return dateComp;
      return b.createdAt.compareTo(a.createdAt);
    });
    return logs.take(limit).toList();
  }

  String getStaffName(String staffId) {
    final matches = _staffList.where((s) => s.staffId == staffId);
    return matches.isNotEmpty ? matches.first.staffName : '不明';
  }

  String getGoalTitle(String goalId) {
    final matches = _goalsList.where((g) => g.goalId == goalId);
    return matches.isNotEmpty ? matches.first.title : '不明';
  }

  Goal? getGoal(String goalId) {
    final matches = _goalsList.where((g) => g.goalId == goalId);
    return matches.isNotEmpty ? matches.first : null;
  }

  String generateId() => _uuid.v4();
}
