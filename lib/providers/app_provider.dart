import 'package:flutter/material.dart';
import '../models/facility.dart';
import '../models/staff.dart';
import '../models/goal.dart';
import '../models/daily_log.dart';
import '../services/database_service.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  Facility? _currentFacility;
  Staff? _currentStaff;
  bool _isInitialized = false;

  Facility? get currentFacility => _currentFacility;
  Staff? get currentStaff => _currentStaff;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _currentFacility != null;
  bool get isStaffSelected => _currentStaff != null;
  DatabaseService get db => _db;

  Future<void> initialize() async {
    await _db.initialize();
    _isInitialized = true;
    notifyListeners();
  }

  /// Refresh all data from Firestore
  Future<void> refreshData() async {
    await _db.refresh();
    // Re-fetch current facility if logged in
    if (_currentFacility != null) {
      _currentFacility = _db.getFacility(_currentFacility!.facilityId);
    }
    notifyListeners();
  }

  List<Facility> get facilities => _db.getAllFacilities();

  bool login(String facilityId, String password) {
    final facility = _db.getFacility(facilityId);
    if (facility == null) return false;
    if (_db.verifyPassword(password, facility.sharedPasswordHash)) {
      _currentFacility = facility;
      notifyListeners();
      return true;
    }
    return false;
  }

  void selectStaff(Staff staff) {
    _currentStaff = staff;
    notifyListeners();
  }

  void logout() {
    _currentFacility = null;
    _currentStaff = null;
    notifyListeners();
  }

  void switchStaff() {
    _currentStaff = null;
    notifyListeners();
  }

  // Staff management
  List<Staff> get staffList =>
      _currentFacility != null
          ? _db.getStaffByFacility(_currentFacility!.facilityId,
              activeOnly: false)
          : [];

  List<Staff> get activeStaffList =>
      _currentFacility != null
          ? _db.getStaffByFacility(_currentFacility!.facilityId)
          : [];

  Future<Staff> addStaff(String name) async {
    final staff = await _db.addStaff(_currentFacility!.facilityId, name);
    notifyListeners();
    return staff;
  }

  Future<void> updateStaff(Staff staff) async {
    await _db.updateStaff(staff);
    notifyListeners();
  }

  Future<void> deleteStaff(String staffId) async {
    if (_currentStaff?.staffId == staffId) {
      _currentStaff = null;
    }
    await _db.deleteStaff(staffId);
    notifyListeners();
  }

  // Goals management
  List<Goal> get goals =>
      _currentFacility != null
          ? _db.getGoalsByFacility(_currentFacility!.facilityId)
          : [];

  List<Goal> get allGoals =>
      _currentFacility != null
          ? _db.getGoalsByFacility(_currentFacility!.facilityId,
              activeOnly: false)
          : [];

  Future<Goal> addGoal(Goal goal) async {
    final result = await _db.addGoal(goal);
    notifyListeners();
    return result;
  }

  Future<void> updateGoal(Goal goal) async {
    await _db.updateGoal(goal);
    notifyListeners();
  }

  Future<void> deleteGoal(String goalId) async {
    await _db.deleteGoal(goalId);
    notifyListeners();
  }

  Future<void> applyTemplate(String templateName) async {
    await _db.applyGoalTemplate(
        _currentFacility!.facilityId, templateName);
    notifyListeners();
  }

  // Facility management
  Future<void> deleteFacility(String facilityId) async {
    await _db.deleteFacility(facilityId);
    if (_currentFacility?.facilityId == facilityId) {
      _currentFacility = null;
      _currentStaff = null;
    }
    notifyListeners();
  }

  // Daily Logs
  Future<void> deleteLog(String logId) async {
    await _db.deleteLog(logId);
    notifyListeners();
  }

  Future<DailyLog> saveLog(DailyLog log) async {
    final result = await _db.saveLog(log);
    notifyListeners();
    return result;
  }

  List<DailyLog> getLogsForStaff() {
    if (_currentStaff == null) return [];
    return _db.getLogsByStaff(_currentStaff!.staffId);
  }

  // Dashboard data
  String? get latestLogDate =>
      _currentFacility != null
          ? _db.getLatestLogDate(_currentFacility!.facilityId)
          : null;

  double get latestDayAverage {
    if (_currentFacility == null) return 0;
    final date = latestLogDate;
    if (date == null) return 0;
    final logs = _db.getLogsByDate(_currentFacility!.facilityId, date);
    return _db.getAverageScore(logs);
  }

  double get monthlyAverage {
    if (_currentFacility == null) return 0;
    final now = DateTime.now();
    final logs = _db.getLogsByMonth(
        _currentFacility!.facilityId, now.year, now.month);
    return _db.getAverageScore(logs);
  }

  Map<String, double> get latestDayAverageByGoal {
    if (_currentFacility == null) return {};
    final date = latestLogDate;
    if (date == null) return {};
    final logs = _db.getLogsByDate(_currentFacility!.facilityId, date);
    return _db.getAverageByGoal(logs);
  }

  Map<String, double> get monthlyAverageByGoal {
    if (_currentFacility == null) return {};
    final now = DateTime.now();
    final logs = _db.getLogsByMonth(
        _currentFacility!.facilityId, now.year, now.month);
    return _db.getAverageByGoal(logs);
  }

  List<DailyLog> get recentComments =>
      _currentFacility != null
          ? _db.getRecentComments(_currentFacility!.facilityId)
          : [];

  // Helpers
  String getStaffName(String staffId) => _db.getStaffName(staffId);
  String getGoalTitle(String goalId) => _db.getGoalTitle(goalId);
  Goal? getGoal(String goalId) => _db.getGoal(goalId);
  String generateId() => _db.generateId();

  String get todayString {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  List<DailyLog> getTodayLogsForCurrentStaff() {
    if (_currentFacility == null || _currentStaff == null) return [];
    return _db
        .getLogsByDate(_currentFacility!.facilityId, todayString)
        .where((l) => l.staffId == _currentStaff!.staffId)
        .toList();
  }
}
