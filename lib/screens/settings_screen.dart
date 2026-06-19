import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import 'goal_management_screen.dart';
import 'staff_management_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final facility = provider.currentFacility;
    final staff = provider.currentStaff;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current session info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: AppTheme.primaryGreen, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        '現在のセッション',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    icon: Icons.business_rounded,
                    label: '施設',
                    value: facility?.facilityName ?? '---',
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.person_rounded,
                    label: 'スタッフ',
                    value: staff?.staffName ?? '---',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Management section
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.assignment_rounded,
                  iconColor: AppTheme.primaryGreen,
                  title: '評価項目管理',
                  subtitle: '評価項目の追加・編集・並び替え',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const GoalManagementScreen()),
                  ),
                ),
                const Divider(height: 1, indent: 60),
                _SettingsTile(
                  icon: Icons.people_alt_rounded,
                  iconColor: AppTheme.primaryBlue,
                  title: 'スタッフ管理',
                  subtitle: 'スタッフの追加・編集・非表示',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StaffManagementScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Monitor link section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.monitor_rounded,
                          color: AppTheme.primaryBlue, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'モニター連携',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Score Monitorアプリで接続する際に、以下の施設IDとパスワードを入力してください。',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '施設ID',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                facility?.facilityId ?? '---',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                  fontFamily: 'monospace',
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                final id = facility?.facilityId;
                                if (id != null) {
                                  Clipboard.setData(ClipboardData(text: id));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('施設IDをコピーしました'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.copy_rounded, size: 20),
                              color: AppTheme.primaryBlue,
                              tooltip: 'コピー',
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.softOrange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16,
                            color: AppTheme.softOrange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'パスワードはこの施設のログインパスワードと同じです',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.softOrange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Cloud sync status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cloud_done_rounded,
                          color: AppTheme.primaryGreen, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'クラウド同期',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle,
                                size: 6, color: AppTheme.primaryGreen),
                            SizedBox(width: 4),
                            Text(
                              '接続中',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Firebase Firestoreを使用してクラウドで自動同期されています。\n全ての端末からリアルタイムでデータにアクセスできます。',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await provider.refreshData();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('データを最新に更新しました'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('手動でデータを更新'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        side: const BorderSide(color: AppTheme.primaryGreen),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Account actions
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.swap_horiz_rounded,
                  iconColor: AppTheme.softOrange,
                  title: 'スタッフを切り替え',
                  subtitle: '別のスタッフとして記録する',
                  onTap: () {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    provider.switchStaff();
                  },
                ),
                const Divider(height: 1, indent: 60),
                _SettingsTile(
                  icon: Icons.delete_forever_rounded,
                  iconColor: AppTheme.error,
                  title: '施設を削除',
                  subtitle: '施設と全てのデータを完全に削除する',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        title: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: AppTheme.error, size: 28),
                            const SizedBox(width: 8),
                            const Text('施設を削除'),
                          ],
                        ),
                        content: Text(
                          '「${facility?.facilityName ?? ""}」を完全に削除しますか？\n\n'
                          '以下の全てのデータが削除されます：\n'
                          '・全スタッフ情報\n'
                          '・全評価項目\n'
                          '・全評価記録\n\n'
                          'この操作は取り消せません。',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('キャンセル'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.error,
                            ),
                            onPressed: () async {
                              // Clear any lingering SnackBars
                              ScaffoldMessenger.of(context).clearSnackBars();
                              final facilityId = facility?.facilityId;
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (facilityId != null) {
                                await provider.deleteFacility(facilityId);
                              }
                            },
                            child: const Text('完全に削除'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 60),
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  iconColor: AppTheme.softOrange,
                  title: 'ログアウト',
                  subtitle: '施設からログアウトする',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        title: const Text('ログアウト'),
                        content: const Text('ログアウトしますか？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('キャンセル'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.error,
                            ),
                            onPressed: () {
                              // Clear any lingering SnackBars before logout
                              ScaffoldMessenger.of(context).clearSnackBars();
                              // Close the dialog first
                              Navigator.pop(ctx);
                              // Then logout (AppGate switches to LoginScreen)
                              provider.logout();
                            },
                            child: const Text('ログアウト'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // App info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppTheme.textSecondary, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'アプリ情報',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'よかレッジ！コミュニティスコア v1.1.0',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '放課後余暇教育プラットフォーム（Firebase版）',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded,
          size: 16, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }
}
