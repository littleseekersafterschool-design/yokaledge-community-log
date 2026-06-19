import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/facility.dart';
import '../models/staff.dart';
import '../models/goal.dart';
import '../models/daily_log.dart';
import '../utils/goal_templates.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Local caches for fast synchronous access
  List<Facility> _facilities = [];
  List<Staff> _staffList = [];
  List<Goal> _goalsList = [];
  List<DailyLog> _logsList = [];

  Future<void> initialize() async {
    await _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadFacilities(),
      _loadStaff(),
      _loadGoals(),
      _loadLogs(),
    ]);
  }

  Future<void> _loadFacilities() async {
    final snap = await _firestore.collection('facilities').get();
    _facilities = snap.docs
        .map((d) => Facility.fromMap(d.data()))
        .toList();
  }

  Future<void> _loadStaff() async {
    final snap = await _firestore.collection('staff').get();
    _staffList = snap.docs
        .map((d) => Staff.fromMap(d.data()))
        .toList();
  }

  Future<void> _loadGoals() async {
    final snap = await _firestore.collection('goals').get();
    _goalsList = snap.docs
        .map((d) => Goal.fromMap(d.data()))
        .toList();
  }

  Future<void> _loadLogs() async {
    final snap = await _firestore.collection('daily_logs').get();
    _logsList = snap.docs
        .map((d) => DailyLog.fromMap(d.data()))
        .toList();
  }

  /// Refresh all caches from Firestore
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

  // ============ Facilities ============

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
    await _firestore
        .collection('facilities')
        .doc(facility.facilityId)
        .set(facility.toMap());
    _facilities.add(facility);
    return facility;
  }

  // ============ Staff ============

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
    await _firestore
        .collection('staff')
        .doc(staff.staffId)
        .set(staff.toMap());
    _staffList.add(staff);
    return staff;
  }

  Future<void> updateStaff(Staff staff) async {
    await _firestore
        .collection('staff')
        .doc(staff.staffId)
        .set(staff.toMap());
    _staffList.removeWhere((s) => s.staffId == staff.staffId);
    _staffList.add(staff);
  }

  Future<void> deleteStaff(String staffId) async {
    await _firestore.collection('staff').doc(staffId).delete();
    _staffList.removeWhere((s) => s.staffId == staffId);
    // Also delete all logs for this staff
    final logsToDelete = _logsList.where((l) => l.staffId == staffId).toList();
    for (final log in logsToDelete) {
      await _firestore.collection('daily_logs').doc(log.logId).delete();
    }
    _logsList.removeWhere((l) => l.staffId == staffId);
  }

  // ============ Goals ============

  List<Goal> getGoalsByFacility(String facilityId, {bool activeOnly = true}) {
    final goals = _goalsList
        .where((g) => g.facilityId == facilityId && (!activeOnly || g.isActive))
        .toList();
    goals.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return goals;
  }

  Future<Goal> addGoal(Goal goal) async {
    await _firestore.collection('goals').doc(goal.goalId).set(goal.toMap());
    _goalsList.add(goal);
    return goal;
  }

  Future<void> updateGoal(Goal goal) async {
    await _firestore.collection('goals').doc(goal.goalId).set(goal.toMap());
    _goalsList.removeWhere((g) => g.goalId == goal.goalId);
    _goalsList.add(goal);
  }

  Future<void> deleteGoal(String goalId) async {
    await _firestore.collection('goals').doc(goalId).delete();
    _goalsList.removeWhere((g) => g.goalId == goalId);
    // Also delete all logs for this goal
    final logsToDelete = _logsList.where((l) => l.goalId == goalId).toList();
    for (final log in logsToDelete) {
      await _firestore.collection('daily_logs').doc(log.logId).delete();
    }
    _logsList.removeWhere((l) => l.goalId == goalId);
  }

  Future<void> applyGoalTemplate(
      String facilityId, String templateName) async {
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

  // ============ Daily Logs ============

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
        .where(
            (l) => l.facilityId == facilityId && l.logDate.startsWith(prefix))
        .toList();
  }

  Future<DailyLog> saveLog(DailyLog log) async {
    // Check for duplicate: same facility, staff, goal, date
    final existing = _logsList.where((l) =>
        l.facilityId == log.facilityId &&
        l.staffId == log.staffId &&
        l.goalId == log.goalId &&
        l.logDate == log.logDate);

    if (existing.isNotEmpty) {
      // Update existing log
      final updated = existing.first.copyWith(
        score: log.score,
        comment: log.comment,
        updatedAt: DateTime.now(),
      );
      await _firestore
          .collection('daily_logs')
          .doc(updated.logId)
          .set(updated.toMap());
      _logsList.removeWhere((l) => l.logId == updated.logId);
      _logsList.add(updated);
      return updated;
    } else {
      await _firestore
          .collection('daily_logs')
          .doc(log.logId)
          .set(log.toMap());
      _logsList.add(log);
      return log;
    }
  }

  Future<void> deleteLog(String logId) async {
    await _firestore.collection('daily_logs').doc(logId).delete();
    _logsList.removeWhere((l) => l.logId == logId);
  }

  Future<void> deleteFacility(String facilityId) async {
    // Delete facility
    await _firestore.collection('facilities').doc(facilityId).delete();
    _facilities.removeWhere((f) => f.facilityId == facilityId);

    // Delete all staff for this facility
    final staffToDelete =
        _staffList.where((s) => s.facilityId == facilityId).toList();
    for (final s in staffToDelete) {
      await _firestore.collection('staff').doc(s.staffId).delete();
    }
    _staffList.removeWhere((s) => s.facilityId == facilityId);

    // Delete all goals for this facility
    final goalsToDelete =
        _goalsList.where((g) => g.facilityId == facilityId).toList();
    for (final g in goalsToDelete) {
      await _firestore.collection('goals').doc(g.goalId).delete();
    }
    _goalsList.removeWhere((g) => g.facilityId == facilityId);

    // Delete all logs for this facility
    final logsToDelete =
        _logsList.where((l) => l.facilityId == facilityId).toList();
    for (final l in logsToDelete) {
      await _firestore.collection('daily_logs').doc(l.logId).delete();
    }
    _logsList.removeWhere((l) => l.facilityId == facilityId);
  }

  // ============ Aggregation ============

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
