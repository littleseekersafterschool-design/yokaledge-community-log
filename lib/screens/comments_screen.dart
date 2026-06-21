import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/daily_log.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';

enum CommentPeriod { week, month, all }

class CommentsScreen extends StatefulWidget {
  const CommentsScreen({super.key});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  CommentPeriod _period = CommentPeriod.week;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final allLogs = provider.getLogsForCurrentFacility();
    final periodLogs = _filterByPeriod(allLogs, _period);
    final commentLogs =
        periodLogs.where((log) => log.comment.trim().isNotEmpty).toList()
          ..sort((a, b) {
            final goalCompare = provider
                .getGoalTitle(a.goalId)
                .compareTo(provider.getGoalTitle(b.goalId));
            if (goalCompare != 0) return goalCompare;
            final dateCompare = b.logDate.compareTo(a.logDate);
            if (dateCompare != 0) return dateCompare;
            return provider
                .getStaffName(a.staffId)
                .compareTo(provider.getStaffName(b.staffId));
          });

    final groupedByGoal = <String, List<DailyLog>>{};
    for (final log in commentLogs) {
      groupedByGoal.putIfAbsent(log.goalId, () => []).add(log);
    }
    final goalIds = groupedByGoal.keys.toList()
      ..sort(
        (a, b) => provider.getGoalTitle(a).compareTo(provider.getGoalTitle(b)),
      );

    return Column(
      children: [
        _SummaryHeader(
          period: _period,
          onChanged: (period) => setState(() => _period = period),
          totalLogs: periodLogs.length,
          commentCount: commentLogs.length,
        ),
        const Divider(height: 1),
        Expanded(
          child: commentLogs.isEmpty
              ? _EmptyComments(period: _period)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: goalIds.length,
                  itemBuilder: (context, goalIndex) {
                    final goalId = goalIds[goalIndex];
                    final goal = provider.getGoal(goalId);
                    final goalTitle = provider.getGoalTitle(goalId);
                    final goalCommentLogs = groupedByGoal[goalId]!;
                    final goalPeriodLogs = periodLogs
                        .where((log) => log.goalId == goalId)
                        .toList();
                    final color = goal != null
                        ? AppTheme.getGoalColor(goal.color)
                        : AppTheme.primaryGreen;
                    final iconData = goal != null
                        ? AppTheme.getGoalIcon(goal.icon)
                        : Icons.star_rounded;

                    final groupedByDate = <String, List<DailyLog>>{};
                    for (final log in goalCommentLogs) {
                      groupedByDate.putIfAbsent(log.logDate, () => []).add(log);
                    }
                    final dates = groupedByDate.keys.toList()
                      ..sort((a, b) => b.compareTo(a));

                    return _GoalCommentSection(
                      color: color,
                      iconData: iconData,
                      goalTitle: goalTitle,
                      averageScore: _averageScore(goalPeriodLogs),
                      totalScoreLogs: goalPeriodLogs.length,
                      totalComments: goalCommentLogs.length,
                      dates: dates,
                      logsByDate: groupedByDate,
                      staffNameFor: provider.getStaffName,
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<DailyLog> _filterByPeriod(List<DailyLog> logs, CommentPeriod period) {
    if (period == CommentPeriod.all) return logs;

    final now = DateTime.now();
    return logs.where((log) {
      final date = DateTime.tryParse(log.logDate);
      if (date == null) return false;

      if (period == CommentPeriod.month) {
        return date.year == now.year && date.month == now.month;
      }

      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final nextWeekStart = weekStart.add(const Duration(days: 7));
      final logDay = DateTime(date.year, date.month, date.day);
      return !logDay.isBefore(weekStart) && logDay.isBefore(nextWeekStart);
    }).toList();
  }

  double? _averageScore(List<DailyLog> logs) {
    if (logs.isEmpty) return null;
    final total = logs.fold<int>(0, (sum, log) => sum + log.score);
    return total / logs.length;
  }
}

class _SummaryHeader extends StatelessWidget {
  final CommentPeriod period;
  final ValueChanged<CommentPeriod> onChanged;
  final int totalLogs;
  final int commentCount;

  const _SummaryHeader({
    required this.period,
    required this.onChanged,
    required this.totalLogs,
    required this.commentCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '施設全体のコメント振り返り',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '評価項目ごとに、期間内のスコア傾向とコメントを日付別で確認できます。',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SegmentedButton<CommentPeriod>(
                  segments: const [
                    ButtonSegment(
                      value: CommentPeriod.week,
                      label: Text('今週'),
                      icon: Icon(Icons.view_week_rounded),
                    ),
                    ButtonSegment(
                      value: CommentPeriod.month,
                      label: Text('今月'),
                      icon: Icon(Icons.calendar_month_rounded),
                    ),
                    ButtonSegment(
                      value: CommentPeriod.all,
                      label: Text('全期間'),
                      icon: Icon(Icons.all_inclusive_rounded),
                    ),
                  ],
                  selected: {period},
                  onSelectionChanged: (selected) => onChanged(selected.first),
                  showSelectedIcon: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                icon: Icons.fact_check_rounded,
                label: '評価',
                value: '$totalLogs件',
              ),
              _MetricChip(
                icon: Icons.comment_rounded,
                label: 'コメント',
                value: '$commentCount件',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryGreen),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCommentSection extends StatelessWidget {
  final Color color;
  final IconData iconData;
  final String goalTitle;
  final double? averageScore;
  final int totalScoreLogs;
  final int totalComments;
  final List<String> dates;
  final Map<String, List<DailyLog>> logsByDate;
  final String Function(String staffId) staffNameFor;

  const _GoalCommentSection({
    required this.color,
    required this.iconData,
    required this.goalTitle,
    required this.averageScore,
    required this.totalScoreLogs,
    required this.totalComments,
    required this.dates,
    required this.logsByDate,
    required this.staffNameFor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(iconData, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goalTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _GoalMetric(
                            label: '平均',
                            value: averageScore == null
                                ? '-'
                                : averageScore!.toStringAsFixed(1),
                            color: averageScore == null
                                ? AppTheme.textSecondary
                                : AppTheme.getScoreColor(averageScore!),
                          ),
                          _GoalMetric(
                            label: '評価',
                            value: '$totalScoreLogs件',
                            color: AppTheme.textSecondary,
                          ),
                          _GoalMetric(
                            label: 'コメント',
                            value: '$totalComments件',
                            color: color,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...dates.map((date) {
              final dateLogs = logsByDate[date]!;
              dateLogs.sort((a, b) {
                final staffCompare = staffNameFor(
                  a.staffId,
                ).compareTo(staffNameFor(b.staffId));
                if (staffCompare != 0) return staffCompare;
                return b.updatedAt.compareTo(a.updatedAt);
              });

              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          date,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${dateLogs.length}件',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...dateLogs.map(
                      (log) => _CommentTile(
                        log: log,
                        staffName: staffNameFor(log.staffId),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _GoalMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _GoalMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          children: [
            TextSpan(text: '$label '),
            TextSpan(
              text: value,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final DailyLog log;
  final String staffName;

  const _CommentTile({required this.log, required this.staffName});

  @override
  Widget build(BuildContext context) {
    final scoreColor = AppTheme.getScoreColor(log.score.toDouble());

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
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
              CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.14),
                child: Text(
                  staffName.isNotEmpty ? staffName[0] : '?',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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
          const SizedBox(height: 8),
          Text(
            log.comment.trim(),
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyComments extends StatelessWidget {
  final CommentPeriod period;

  const _EmptyComments({required this.period});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.comment_rounded, size: 64, color: AppTheme.divider),
            const SizedBox(height: 16),
            Text(
              '${_periodLabel(period)}のコメントはありません',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              '評価入力でコメントを保存すると、施設全体の振り返りとして表示されます。',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _periodLabel(CommentPeriod period) {
    switch (period) {
      case CommentPeriod.week:
        return '今週';
      case CommentPeriod.month:
        return '今月';
      case CommentPeriod.all:
        return '全期間';
    }
  }
}
