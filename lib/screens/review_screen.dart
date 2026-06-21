import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/daily_log.dart';
import '../providers/app_provider.dart';
import '../services/ai_review_service.dart';
import '../utils/app_theme.dart';

enum ReviewPeriod { week, month, all }

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final AiReviewService _reviewService = AiReviewService();
  ReviewPeriod _period = ReviewPeriod.week;
  bool _isGenerating = false;
  String? _report;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final logs = _filterByPeriod(provider.getLogsForCurrentFacility(), _period);
    final comments = logs.where((log) => log.comment.trim().isNotEmpty).length;
    final average = _averageScore(logs);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'AIレビュー',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '選択した期間のスコアと記録をAIが読み取り、振り返りレポートとしてまとめます。',
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        SegmentedButton<ReviewPeriod>(
          segments: const [
            ButtonSegment(
              value: ReviewPeriod.week,
              label: Text('今週'),
              icon: Icon(Icons.view_week_rounded),
            ),
            ButtonSegment(
              value: ReviewPeriod.month,
              label: Text('今月'),
              icon: Icon(Icons.calendar_month_rounded),
            ),
            ButtonSegment(
              value: ReviewPeriod.all,
              label: Text('全期間'),
              icon: Icon(Icons.all_inclusive_rounded),
            ),
          ],
          selected: {_period},
          showSelectedIcon: false,
          onSelectionChanged: (selected) {
            setState(() {
              _period = selected.first;
              _report = null;
              _error = null;
            });
          },
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetricChip(label: '評価', value: '${logs.length}件'),
            _MetricChip(label: 'コメント', value: '$comments件'),
            _MetricChip(
              label: '平均',
              value: average == null ? '-' : average.toStringAsFixed(1),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isGenerating || logs.isEmpty
                ? null
                : () => _generate(provider, logs),
            icon: _isGenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: Text(_isGenerating ? 'レポート作成中...' : 'AIレポートを作成'),
          ),
        ),
        if (logs.isEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            '選択した期間に評価記録がありません。',
            style: TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 16),
          _ErrorBox(message: _error!),
        ],
        if (_report != null) ...[
          const SizedBox(height: 16),
          _ReportCard(report: _report!),
        ],
        const SizedBox(height: 18),
        _PreviewRecords(logs: logs, provider: provider),
      ],
    );
  }

  Future<void> _generate(AppProvider provider, List<DailyLog> logs) async {
    setState(() {
      _isGenerating = true;
      _error = null;
      _report = null;
    });

    try {
      final report = await _reviewService.generateReport(
        facilityName: provider.currentFacility?.facilityName ?? '施設',
        periodLabel: _periodLabel(_period),
        records: _recordsForAi(provider, logs),
      );
      if (mounted) {
        setState(() => _report = report);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  List<Map<String, dynamic>> _recordsForAi(
    AppProvider provider,
    List<DailyLog> logs,
  ) {
    return logs
        .map(
          (log) => {
            'date': log.logDate,
            'staff': provider.getStaffName(log.staffId),
            'goal': provider.getGoalTitle(log.goalId),
            'score': log.score,
            'comment': log.comment,
          },
        )
        .toList();
  }

  List<DailyLog> _filterByPeriod(List<DailyLog> logs, ReviewPeriod period) {
    if (period == ReviewPeriod.all) return logs;

    final now = DateTime.now();
    return logs.where((log) {
      final date = DateTime.tryParse(log.logDate);
      if (date == null) return false;
      if (period == ReviewPeriod.month) {
        return date.year == now.year && date.month == now.month;
      }

      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final nextWeekStart = weekStart.add(const Duration(days: 7));
      final logDate = DateTime(date.year, date.month, date.day);
      return !logDate.isBefore(weekStart) && logDate.isBefore(nextWeekStart);
    }).toList();
  }

  double? _averageScore(List<DailyLog> logs) {
    if (logs.isEmpty) return null;
    return logs.fold<int>(0, (sum, log) => sum + log.score) / logs.length;
  }

  String _periodLabel(ReviewPeriod period) {
    switch (period) {
      case ReviewPeriod.week:
        return '今週';
      case ReviewPeriod.month:
        return '今月';
      case ReviewPeriod.all:
        return '全期間';
    }
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryGreen),
                SizedBox(width: 8),
                Text(
                  'AIレポート',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              report,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.25)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppTheme.error, fontSize: 13),
      ),
    );
  }
}

class _PreviewRecords extends StatelessWidget {
  final List<DailyLog> logs;
  final AppProvider provider;

  const _PreviewRecords({required this.logs, required this.provider});

  @override
  Widget build(BuildContext context) {
    final preview = logs.take(8).toList();
    if (preview.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '対象記録の一部',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...preview.map(
          (log) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              dense: true,
              title: Text(
                '${log.logDate} / ${provider.getGoalTitle(log.goalId)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${provider.getStaffName(log.staffId)}  スコア ${log.score}'
                '${log.comment.trim().isEmpty ? "" : "\n${log.comment.trim()}"}',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
