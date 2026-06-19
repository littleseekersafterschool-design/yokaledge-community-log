import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/goal.dart';
import '../utils/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final latestAvg = provider.latestDayAverage;
    final monthlyAvg = provider.monthlyAverage;
    final latestDate = provider.latestLogDate ?? '---';
    final goals = provider.goals;
    final latestByGoal = provider.latestDayAverageByGoal;
    final monthlyByGoal = provider.monthlyAverageByGoal;
    final recentComments = provider.recentComments;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score summary cards
          Row(
            children: [
              Expanded(
                child: _ScoreCard(
                  title: '最新日平均',
                  subtitle: latestDate,
                  score: latestAvg,
                  icon: Icons.today_rounded,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ScoreCard(
                  title: '今月平均',
                  subtitle: _currentMonthLabel(),
                  score: monthlyAvg,
                  icon: Icons.calendar_month_rounded,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Goal-level scores
          _SectionHeader(
            title: '評価項目別スコア',
            icon: Icons.assessment_rounded,
          ),
          const SizedBox(height: 12),
          ...goals.map((goal) => _GoalScoreRow(
                goal: goal,
                latestScore: latestByGoal[goal.goalId],
                monthlyScore: monthlyByGoal[goal.goalId],
              )),

          const SizedBox(height: 24),

          // Recent comments
          _SectionHeader(
            title: '最新コメント',
            icon: Icons.chat_bubble_outline_rounded,
          ),
          const SizedBox(height: 12),
          if (recentComments.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.comment_outlined,
                          size: 40, color: AppTheme.divider),
                      const SizedBox(height: 12),
                      Text(
                        'コメントはまだありません',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...recentComments.take(10).map((log) {
              final goal = provider.getGoal(log.goalId);
              return _CommentCard(
                staffName: provider.getStaffName(log.staffId),
                goalTitle: provider.getGoalTitle(log.goalId),
                score: log.score,
                comment: log.comment,
                date: log.logDate,
                goalColor: goal != null
                    ? AppTheme.getGoalColor(goal.color)
                    : AppTheme.primaryGreen,
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _currentMonthLabel() {
    final now = DateTime.now();
    return '${now.year}年${now.month}月';
  }
}

class _ScoreCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double score;
  final IconData icon;
  final Color color;

  const _ScoreCard({
    required this.title,
    required this.subtitle,
    required this.score,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  score > 0 ? score.toStringAsFixed(1) : '---',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: score > 0
                        ? AppTheme.getScoreColor(score)
                        : AppTheme.textSecondary,
                  ),
                ),
                if (score > 0) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '/ 5.0',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (score > 0)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: score / 5.0,
                  backgroundColor: color.withValues(alpha: 0.15),
                  color: color,
                  minHeight: 6,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _GoalScoreRow extends StatelessWidget {
  final Goal goal;
  final double? latestScore;
  final double? monthlyScore;

  const _GoalScoreRow({
    required this.goal,
    this.latestScore,
    this.monthlyScore,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getGoalColor(goal.color);
    final iconData = AppTheme.getGoalIcon(goal.icon);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    goal.category,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('最新日 ',
                        style: TextStyle(
                            fontSize: 10, color: AppTheme.textSecondary)),
                    Text(
                      latestScore != null
                          ? latestScore!.toStringAsFixed(1)
                          : '---',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: latestScore != null
                            ? AppTheme.getScoreColor(latestScore!)
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('月間 ',
                        style: TextStyle(
                            fontSize: 10, color: AppTheme.textSecondary)),
                    Text(
                      monthlyScore != null
                          ? monthlyScore!.toStringAsFixed(1)
                          : '---',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: monthlyScore != null
                            ? AppTheme.getScoreColor(monthlyScore!)
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final String staffName;
  final String goalTitle;
  final int score;
  final String comment;
  final String date;
  final Color goalColor;

  const _CommentCard({
    required this.staffName,
    required this.goalTitle,
    required this.score,
    required this.comment,
    required this.date,
    required this.goalColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: goalColor.withValues(alpha: 0.15),
                  child: Text(
                    staffName.isNotEmpty ? staffName[0] : '?',
                    style: TextStyle(
                      color: goalColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staffName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '$goalTitle  $date',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.getScoreColor(score.toDouble())
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded,
                          size: 14,
                          color: AppTheme.getScoreColor(score.toDouble())),
                      const SizedBox(width: 2),
                      Text(
                        '$score',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppTheme.getScoreColor(score.toDouble()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                comment,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
