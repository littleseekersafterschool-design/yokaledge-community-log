import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/daily_log.dart';
import '../utils/app_theme.dart';

class EvaluationInputScreen extends StatefulWidget {
  const EvaluationInputScreen({super.key});

  @override
  State<EvaluationInputScreen> createState() => _EvaluationInputScreenState();
}

class _EvaluationInputScreenState extends State<EvaluationInputScreen> {
  final Map<String, int> _scores = {};
  final Map<String, TextEditingController> _commentControllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingLogs());
  }

  void _loadExistingLogs() {
    final provider = context.read<AppProvider>();
    final todayLogs = provider.getTodayLogsForCurrentStaff();
    for (final log in todayLogs) {
      _scores[log.goalId] = log.score;
      _getController(log.goalId).text = log.comment;
    }
    if (mounted) setState(() {});
  }

  TextEditingController _getController(String goalId) {
    return _commentControllers.putIfAbsent(
      goalId,
      () => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final c in _commentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final provider = context.read<AppProvider>();
    final facility = provider.currentFacility!;
    final staff = provider.currentStaff!;

    for (final entry in _scores.entries) {
      final log = DailyLog(
        logId: provider.generateId(),
        facilityId: facility.facilityId,
        staffId: staff.staffId,
        goalId: entry.key,
        score: entry.value,
        comment: _getController(entry.key).text.trim(),
        logDate: provider.todayString,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await provider.saveLog(log);
    }

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Text('評価を保存しました'),
            ],
          ),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final goals = provider.goals;
    final staff = provider.currentStaff;
    final today = provider.todayString;

    return Column(
      children: [
        // Header info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 18, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Text(
                today,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Icon(Icons.person_rounded,
                  size: 18, color: AppTheme.primaryBlue),
              const SizedBox(width: 6),
              Text(
                staff?.staffName ?? '',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Goal evaluation list
        Expanded(
          child: goals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.playlist_add_rounded,
                          size: 56, color: AppTheme.divider),
                      const SizedBox(height: 16),
                      const Text(
                        '評価項目がありません',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '設定から評価項目を追加してください',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: goals.length + 1,
                  itemBuilder: (context, index) {
                    if (index == goals.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _save,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Text(
                                _isSaving ? '保存中...' : '評価を保存する'),
                          ),
                        ),
                      );
                    }

                    final goal = goals[index];
                    final color = AppTheme.getGoalColor(goal.color);
                    final iconData = AppTheme.getGoalIcon(goal.icon);
                    final currentScore = _scores[goal.goalId];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Goal header
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child:
                                      Icon(iconData, color: color, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        goal.title,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        goal.description,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Score buttons
                            Row(
                              children: List.generate(5, (i) {
                                final score = i + 1;
                                final isSelected = currentScore == score;
                                final scoreColor =
                                    AppTheme.getScoreColor(score.toDouble());

                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        right: i < 4 ? 6 : 0),
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        if (_scores[goal.goalId] == score) {
                                          _scores.remove(goal.goalId);
                                        } else {
                                          _scores[goal.goalId] = score;
                                        }
                                      }),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? scoreColor
                                              : scoreColor
                                                  .withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isSelected
                                                ? scoreColor
                                                : scoreColor
                                                    .withValues(alpha: 0.3),
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              '$score',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? Colors.white
                                                    : scoreColor,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              DailyLog.scoreLabel(score),
                                              style: TextStyle(
                                                fontSize: 8,
                                                color: isSelected
                                                    ? Colors.white
                                                        .withValues(
                                                            alpha: 0.9)
                                                    : AppTheme.textSecondary,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 12),

                            // Comment input
                            TextField(
                              controller: _getController(goal.goalId),
                              maxLines: 2,
                              minLines: 1,
                              decoration: InputDecoration(
                                hintText: 'コメントを入力（任意）',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary
                                      .withValues(alpha: 0.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                filled: true,
                                fillColor: AppTheme.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
