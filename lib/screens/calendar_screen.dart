import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/daily_log.dart';
import '../utils/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedMonth;
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
    final now = DateTime.now();
    _selectedDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Column(
      children: [
        // Upper half: Calendar + selected day logs
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildCalendar(provider),
              Expanded(child: _buildSelectedDayLogs(provider)),
            ],
          ),
        ),
        // Divider
        Container(height: 1, color: AppTheme.divider),
        // Lower half: Monthly average score graph
        Expanded(
          flex: 1,
          child: _buildMonthlyGraph(provider),
        ),
      ],
    );
  }

  Widget _buildCalendar(AppProvider provider) {
    final facilityId = provider.currentFacility?.facilityId;
    if (facilityId == null) return const SizedBox.shrink();

    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final startWeekday = firstDay.weekday % 7; // Sunday = 0

    // Get logs for this month to show score indicators
    final monthLogs = provider.db.getLogsByMonth(facilityId, year, month);
    final logsByDate = <String, List<DailyLog>>{};
    for (final log in monthLogs) {
      logsByDate.putIfAbsent(log.logDate, () => []).add(log);
    }

    final weekDayLabels = ['日', '月', '火', '水', '木', '金', '土'];
    final now = DateTime.now();
    final todayStr = _dateToString(now);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: _previousMonth,
                color: AppTheme.textSecondary,
                iconSize: 28,
              ),
              Text(
                '$year年${month}月',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: _nextMonth,
                color: AppTheme.textSecondary,
                iconSize: 28,
              ),
            ],
          ),
          // Weekday headers
          Row(
            children: weekDayLabels.map((label) {
              final isSunday = label == '日';
              final isSaturday = label == '土';
              return Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSunday
                          ? AppTheme.error
                          : isSaturday
                              ? AppTheme.primaryBlue
                              : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 2),
          // Calendar grid
          ...List.generate(
            ((lastDay.day + startWeekday - 1) ~/ 7) + 1,
            (weekIndex) {
              return Row(
                children: List.generate(7, (dayIndex) {
                  final dayNum = weekIndex * 7 + dayIndex - startWeekday + 1;
                  if (dayNum < 1 || dayNum > lastDay.day) {
                    return const Expanded(child: SizedBox(height: 38));
                  }

                  final dateStr = _dateToString(DateTime(year, month, dayNum));
                  final isSelected = dateStr == _selectedDate;
                  final isToday = dateStr == todayStr;
                  final hasLogs = logsByDate.containsKey(dateStr);
                  final dayLogs = logsByDate[dateStr] ?? [];
                  final dayAvg = dayLogs.isEmpty
                      ? 0.0
                      : dayLogs.fold<int>(0, (s, l) => s + l.score) /
                          dayLogs.length;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedDate = dateStr);
                      },
                      child: Container(
                        height: 38,
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : isToday
                                  ? AppTheme.lightGreen
                                  : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$dayNum',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isToday || isSelected
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
                            if (hasLogs)
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(top: 1),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.getScoreColor(dayAvg),
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
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayLogs(AppProvider provider) {
    if (_selectedDate == null || provider.currentFacility == null) {
      return const Center(
        child: Text('日付を選択してください', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    final logs = provider.db
        .getLogsByDate(provider.currentFacility!.facilityId, _selectedDate!);

    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_rounded, size: 32, color: AppTheme.divider),
            const SizedBox(height: 6),
            Text(
              '$_selectedDate\n記録なし',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Group by staff
    final logsByStaff = <String, List<DailyLog>>{};
    for (final log in logs) {
      logsByStaff.putIfAbsent(log.staffId, () => []).add(log);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 14, color: AppTheme.primaryGreen),
              const SizedBox(width: 6),
              Text(
                _selectedDate!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${logs.length}件の記録',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        ...logsByStaff.entries.map((entry) {
          final staffName = provider.getStaffName(entry.key);
          final staffLogs = entry.value;
          final staffAvg =
              staffLogs.fold<int>(0, (s, l) => s + l.score) / staffLogs.length;

          return Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            AppTheme.primaryGreen.withValues(alpha: 0.15),
                        child: Text(
                          staffName.isNotEmpty ? staffName[0] : '?',
                          style: const TextStyle(
                            fontSize: 10,
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
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.getScoreColor(staffAvg)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '平均 ${staffAvg.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getScoreColor(staffAvg),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: staffLogs.map((log) {
                      final goal = provider.getGoal(log.goalId);
                      final goalTitle = provider.getGoalTitle(log.goalId);
                      final color = goal != null
                          ? AppTheme.getGoalColor(goal.color)
                          : AppTheme.primaryGreen;
                      return Tooltip(
                        message: '$goalTitle: ${log.score}点'
                            '${log.comment.isNotEmpty ? '\n${log.comment}' : ''}',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: color.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                goal != null
                                    ? AppTheme.getGoalIcon(goal.icon)
                                    : Icons.star,
                                size: 12,
                                color: color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${log.score}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.getScoreColor(
                                      log.score.toDouble()),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMonthlyGraph(AppProvider provider) {
    final facilityId = provider.currentFacility?.facilityId;
    if (facilityId == null) {
      return const Center(child: Text('施設が選択されていません'));
    }

    // Get last 6 months of data
    final now = DateTime.now();
    final monthlyData = <_MonthData>[];

    for (var i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final logs = provider.db.getLogsByMonth(facilityId, date.year, date.month);
      final avg = logs.isEmpty
          ? 0.0
          : logs.fold<int>(0, (s, l) => s + l.score) / logs.length;
      monthlyData.add(_MonthData(
        year: date.year,
        month: date.month,
        average: avg,
        logCount: logs.length,
      ));
    }

    final hasData = monthlyData.any((m) => m.logCount > 0);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  size: 20, color: AppTheme.primaryGreen),
              const SizedBox(width: 6),
              const Text(
                '月別平均スコア',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '過去6ヶ月',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: hasData
                ? _BarChart(data: monthlyData)
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bar_chart_rounded,
                            size: 48, color: AppTheme.divider),
                        const SizedBox(height: 8),
                        Text(
                          'データがありません',
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MonthData {
  final int year;
  final int month;
  final double average;
  final int logCount;

  _MonthData({
    required this.year,
    required this.month,
    required this.average,
    required this.logCount,
  });

  String get label => '${month}月';
  String get fullLabel => '$year/${month.toString().padLeft(2, '0')}';
}

class _BarChart extends StatelessWidget {
  final List<_MonthData> data;

  const _BarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _BarChartPainter(data: data),
        );
      },
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<_MonthData> data;

  _BarChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final leftPadding = 30.0;
    final bottomPadding = 36.0;
    final topPadding = 8.0;
    final chartWidth = size.width - leftPadding - 12;
    final chartHeight = size.height - bottomPadding - topPadding;

    // Draw Y-axis labels and grid lines
    final gridPaint = Paint()
      ..color = AppTheme.divider
      ..strokeWidth = 0.5;

    for (var i = 0; i <= 5; i++) {
      final y = topPadding + chartHeight - (chartHeight * i / 5);

      // Grid line
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - 12, y),
        gridPaint,
      );

      // Y-axis label
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$i',
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    // Draw bars
    final barCount = data.length;
    if (barCount == 0) return;

    final barGroupWidth = chartWidth / barCount;
    final barWidth = barGroupWidth * 0.55;
    final barSpacing = (barGroupWidth - barWidth) / 2;

    for (var i = 0; i < data.length; i++) {
      final item = data[i];
      final x = leftPadding + i * barGroupWidth + barSpacing;
      final barHeight = (item.average / 5.0) * chartHeight;
      final barTop = topPadding + chartHeight - barHeight;

      if (item.logCount > 0) {
        // Bar fill with gradient effect
        final barColor = AppTheme.getScoreColor(item.average);
        final barRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, barTop, barWidth, barHeight),
          const Radius.circular(6),
        );

        final barPaint = Paint()
          ..color = barColor.withValues(alpha: 0.75)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(barRect, barPaint);

        // Bar border
        final borderPaint = Paint()
          ..color = barColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawRRect(barRect, borderPaint);

        // Score value on top
        final scorePainter = TextPainter(
          text: TextSpan(
            text: item.average.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: barColor,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        scorePainter.layout();
        scorePainter.paint(
          canvas,
          Offset(x + barWidth / 2 - scorePainter.width / 2, barTop - 14),
        );
      } else {
        // No data indicator
        final noDataPaint = Paint()
          ..color = AppTheme.divider
          ..style = PaintingStyle.fill;
        final noDataRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
              x, topPadding + chartHeight - 4, barWidth, 4),
          const Radius.circular(2),
        );
        canvas.drawRRect(noDataRect, noDataPaint);
      }

      // Month label
      final labelPainter = TextPainter(
        text: TextSpan(
          text: item.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(
          x + barWidth / 2 - labelPainter.width / 2,
          topPadding + chartHeight + 6,
        ),
      );

      // Count label
      if (item.logCount > 0) {
        final countPainter = TextPainter(
          text: TextSpan(
            text: '${item.logCount}件',
            style: TextStyle(
              fontSize: 9,
              color: AppTheme.textSecondary,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        countPainter.layout();
        countPainter.paint(
          canvas,
          Offset(
            x + barWidth / 2 - countPainter.width / 2,
            topPadding + chartHeight + 20,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
