import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/daily_log.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedMonth;
  late String _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = _dateToString(now);
  }

  static String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _moveMonth(int offset) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + offset,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Column(
      children: [
        _CalendarGrid(
          focusedMonth: _focusedMonth,
          selectedDate: _selectedDate,
          onPrevious: () => _moveMonth(-1),
          onNext: () => _moveMonth(1),
          onDateSelected: (date) => setState(() => _selectedDate = date),
        ),
        const Divider(height: 1),
        Expanded(
          child: _SelectedDayRecords(
            selectedDate: _selectedDate,
            provider: provider,
          ),
        ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final String selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<String> onDateSelected;

  const _CalendarGrid({
    required this.focusedMonth,
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final facilityId = provider.currentFacility?.facilityId;
    final year = focusedMonth.year;
    final month = focusedMonth.month;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final startWeekday = firstDay.weekday % 7;
    final logsByDate = <String, List<DailyLog>>{};

    if (facilityId != null) {
      final monthLogs = provider.db.getLogsByMonth(facilityId, year, month);
      for (final log in monthLogs) {
        logsByDate.putIfAbsent(log.logDate, () => []).add(log);
      }
    }

    final today = _CalendarScreenState._dateToString(DateTime.now());
    final weekdayLabels = ['日', '月', '火', '水', '木', '金', '土'];
    final weekCount = ((lastDay.day + startWeekday - 1) ~/ 7) + 1;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: onPrevious,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$year年 $month月',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: onNext,
              ),
            ],
          ),
          Row(
            children: weekdayLabels.asMap().entries.map((entry) {
              final index = entry.key;
              return Expanded(
                child: Center(
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: index == 0
                          ? AppTheme.error
                          : index == 6
                          ? AppTheme.primaryBlue
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          ...List.generate(weekCount, (weekIndex) {
            return Row(
              children: List.generate(7, (dayIndex) {
                final day = weekIndex * 7 + dayIndex - startWeekday + 1;
                if (day < 1 || day > lastDay.day) {
                  return const Expanded(child: SizedBox(height: 42));
                }

                final date = _CalendarScreenState._dateToString(
                  DateTime(year, month, day),
                );
                final isSelected = date == selectedDate;
                final isToday = date == today;
                final dayLogs = logsByDate[date] ?? [];
                final average = dayLogs.isEmpty
                    ? null
                    : dayLogs.fold<int>(0, (sum, log) => sum + log.score) /
                          dayLogs.length;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onDateSelected(date),
                    child: Container(
                      height: 42,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryGreen
                            : isToday
                            ? AppTheme.lightGreen
                            : null,
                        borderRadius: BorderRadius.circular(10),
                        border: isToday && !isSelected
                            ? Border.all(color: AppTheme.primaryGreen)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : dayIndex == 0
                                  ? AppTheme.error
                                  : dayIndex == 6
                                  ? AppTheme.primaryBlue
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (average != null)
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.getScoreColor(average),
                              ),
                            )
                          else
                            const SizedBox(height: 7),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }
}

class _SelectedDayRecords extends StatelessWidget {
  final String selectedDate;
  final AppProvider provider;

  const _SelectedDayRecords({
    required this.selectedDate,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final facility = provider.currentFacility;
    if (facility == null) {
      return const Center(child: Text('施設が選択されていません'));
    }

    final logs = provider.db.getLogsByDate(facility.facilityId, selectedDate)
      ..sort((a, b) {
        final staffCompare = provider
            .getStaffName(a.staffId)
            .compareTo(provider.getStaffName(b.staffId));
        if (staffCompare != 0) return staffCompare;
        return provider
            .getGoalTitle(a.goalId)
            .compareTo(provider.getGoalTitle(b.goalId));
      });

    if (logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy_rounded, size: 48, color: AppTheme.divider),
              const SizedBox(height: 12),
              Text(
                '$selectedDate の記録はありません',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final logsByStaff = <String, List<DailyLog>>{};
    for (final log in logs) {
      logsByStaff.putIfAbsent(log.staffId, () => []).add(log);
    }
    final staffIds = logsByStaff.keys.toList()
      ..sort(
        (a, b) => provider.getStaffName(a).compareTo(provider.getStaffName(b)),
      );

    final dayAverage =
        logs.fold<int>(0, (sum, log) => sum + log.score) / logs.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(width: 6),
            Text(
              selectedDate,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 10),
            _InfoPill(label: '記録', value: '${logs.length}件'),
            const SizedBox(width: 6),
            _InfoPill(label: '平均', value: dayAverage.toStringAsFixed(1)),
          ],
        ),
        const SizedBox(height: 12),
        ...staffIds.map((staffId) {
          final staffLogs = logsByStaff[staffId]!;
          final staffName = provider.getStaffName(staffId);
          final staffAverage =
              staffLogs.fold<int>(0, (sum, log) => sum + log.score) /
              staffLogs.length;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: AppTheme.primaryGreen.withValues(
                          alpha: 0.14,
                        ),
                        child: Text(
                          staffName.isNotEmpty ? staffName[0] : '?',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          staffName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      _InfoPill(
                        label: '平均',
                        value: staffAverage.toStringAsFixed(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...staffLogs.map((log) {
                    final goal = provider.getGoal(log.goalId);
                    return _LogDetailTile(
                      log: log,
                      goalTitle: provider.getGoalTitle(log.goalId),
                      goalIcon: goal != null
                          ? AppTheme.getGoalIcon(goal.icon)
                          : Icons.star_rounded,
                      goalColor: goal != null
                          ? AppTheme.getGoalColor(goal.color)
                          : AppTheme.primaryGreen,
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _InfoPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _LogDetailTile extends StatelessWidget {
  final DailyLog log;
  final String goalTitle;
  final IconData goalIcon;
  final Color goalColor;

  const _LogDetailTile({
    required this.log,
    required this.goalTitle,
    required this.goalIcon,
    required this.goalColor,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = AppTheme.getScoreColor(log.score.toDouble());

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: goalColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(goalIcon, size: 16, color: goalColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  goalTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'スコア ${log.score}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scoreColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            log.comment.trim().isEmpty ? 'コメントなし' : log.comment.trim(),
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: log.comment.trim().isEmpty
                  ? AppTheme.textSecondary
                  : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
