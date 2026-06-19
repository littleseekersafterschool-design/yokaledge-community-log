import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';

class StaffSelectScreen extends StatefulWidget {
  const StaffSelectScreen({super.key});

  @override
  State<StaffSelectScreen> createState() => _StaffSelectScreenState();
}

class _StaffSelectScreenState extends State<StaffSelectScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addStaff() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('新しいスタッフを追加'),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'スタッフ名を入力',
            prefixIcon: Icon(Icons.person_add),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.trim().isNotEmpty) {
                await context
                    .read<AppProvider>()
                    .addStaff(_nameController.text.trim());
                _nameController.clear();
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final staffList = provider.activeStaffList;
    final facility = provider.currentFacility;

    return Scaffold(
      appBar: AppBar(
        title: Text(facility?.facilityName ?? ''),
        leading: IconButton(
          icon: const Icon(Icons.logout_rounded),
          onPressed: () {
            // AppGate will automatically switch to LoginScreen
            provider.logout();
          },
          tooltip: 'ログアウト',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.people_alt_rounded,
                        color: AppTheme.primaryGreen, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '記録するスタッフを選択',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '今日の評価を記録するスタッフを選んでください',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: staffList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_off_rounded,
                                size: 64, color: AppTheme.divider),
                            const SizedBox(height: 16),
                            const Text(
                              'スタッフが登録されていません',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '右下のボタンからスタッフを追加してください',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: staffList.length,
                        itemBuilder: (context, index) {
                          final staff = staffList[index];
                          final colors = [
                            AppTheme.primaryGreen,
                            AppTheme.primaryBlue,
                            AppTheme.softOrange,
                            AppTheme.softPurple,
                            const Color(0xFF4DB6AC),
                            const Color(0xFFF48FB1),
                          ];
                          final color = colors[index % colors.length];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Card(
                              child: InkWell(
                                onTap: () {
                                  // AppGate will automatically switch to MainShell
                                  provider.selectStaff(staff);
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 18),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 26,
                                        backgroundColor:
                                            color.withValues(alpha: 0.15),
                                        child: Text(
                                          staff.staffName.isNotEmpty
                                              ? staff.staffName[0]
                                              : '?',
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          staff.staffName,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.arrow_forward_ios_rounded,
                                          color: AppTheme.textSecondary,
                                          size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addStaff,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('新しいスタッフ'),
      ),
    );
  }
}
