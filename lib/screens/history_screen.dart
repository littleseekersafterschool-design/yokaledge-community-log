import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/daily_log.dart';
import '../utils/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  void _confirmDeleteLog(DailyLog log, String goalTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('評価記録を削除'),
        content: Text(
          '${log.logDate}の「$goalTitle」の記録を削除しますか？\n\nこの操作は取り消せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              await context.read<AppProvider>().deleteLog(log.logId);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$goalTitleの記録を削除しました'),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final logs = provider.getLogsForStaff();
    final staff = provider.currentStaff;

    // Group logs by date
    final groupedByDate = <String, List<DailyLog>>{};
    for (final log in logs) {
      groupedByDate.putIfAbsent(log.logDate, () => []).add(log);
    }
    final dates = groupedByDate.keys.toList()..sort((a, b) => b.compareTo(a));

    return logs.isEmpty
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_rounded, size: 64, color: AppTheme.divider),
                const SizedBox(height: 16),
                Text(
                  '${staff?.staffName ?? ""}さんの評価履歴はありません',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '評価を入力すると、ここに履歴が表示されます',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dates.length,
            itemBuilder: (context, dateIndex) {
              final date = dates[dateIndex];
              final dateLogs = groupedByDate[date]!;
              final dayAvg = dateLogs.fold<int>(0, (s, l) => s + l.score) /
                  dateLogs.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date header
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                date,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '平均 ${dayAvg.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.getScoreColor(dayAvg),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Log entries for this date
                  ...dateLogs.map((log) {
                    final goal = provider.getGoal(log.goalId);
                    final goalTitle = provider.getGoalTitle(log.goalId);
                    final color = goal != null
                        ? AppTheme.getGoalColor(goal.color)
                        : AppTheme.primaryGreen;
                    final iconData = goal != null
                        ? AppTheme.getGoalIcon(goal.icon)
                        : Icons.star;

                    return Dismissible(
                      key: ValueKey(log.logId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete_rounded,
                            color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            title: const Text('評価記録を削除'),
                            content: Text(
                              '${log.logDate}の「$goalTitle」の記録を削除しますか？',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('キャンセル'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.error),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('削除'),
                              ),
                            ],
                          ),
                        ) ?? false;
                      },
                      onDismissed: (direction) async {
                        await provider.deleteLog(log.logId);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$goalTitleの記録を削除しました'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onLongPress: () =>
                              _confirmDeleteLog(log, goalTitle),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child:
                                      Icon(iconData, color: color, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        goalTitle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      if (log.comment.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          log.comment,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppTheme.getScoreColor(
                                                log.score.toDouble())
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${log.score}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.getScoreColor(
                                                log.score.toDouble()),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DailyLog.scoreLabel(log.score),
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  if (dateIndex < dates.length - 1) const SizedBox(height: 8),
                ],
              );
            },
          );
  }
}
