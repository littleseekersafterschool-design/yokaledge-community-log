import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  void _addStaff() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('新しいスタッフを追加'),
        content: TextField(
          controller: controller,
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
              if (controller.text.trim().isNotEmpty) {
                await context
                    .read<AppProvider>()
                    .addStaff(controller.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteStaff(staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('スタッフを削除'),
        content: Text(
          '「${staff.staffName}」を削除しますか？\n\nこのスタッフに関連する全ての評価記録も削除されます。この操作は取り消せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              await context.read<AppProvider>().deleteStaff(staff.staffId);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${staff.staffName}を削除しました'),
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

  void _editStaff(staff) {
    final controller = TextEditingController(text: staff.staffName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('スタッフ名を編集'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'スタッフ名を入力',
            prefixIcon: Icon(Icons.edit),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final updated =
                    staff.copyWith(staffName: controller.text.trim());
                await context.read<AppProvider>().updateStaff(updated);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final staffList = provider.staffList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('スタッフ管理'),
      ),
      body: staffList.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline_rounded,
                      size: 64, color: AppTheme.divider),
                  const SizedBox(height: 16),
                  const Text(
                    'スタッフが登録されていません',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
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

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Opacity(
                    opacity: staff.isActive ? 1.0 : 0.5,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.15),
                        child: Text(
                          staff.staffName.isNotEmpty
                              ? staff.staffName[0]
                              : '?',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        staff.staffName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        staff.isActive ? '有効' : '非表示',
                        style: TextStyle(
                          fontSize: 12,
                          color: staff.isActive
                              ? AppTheme.primaryGreen
                              : AppTheme.textSecondary,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              staff.isActive
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: staff.isActive
                                  ? AppTheme.primaryGreen
                                  : AppTheme.textSecondary,
                              size: 22,
                            ),
                            onPressed: () async {
                              await provider.updateStaff(
                                staff.copyWith(isActive: !staff.isActive),
                              );
                            },
                            tooltip: staff.isActive ? '非表示にする' : '表示する',
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 22),
                            onPressed: () => _editStaff(staff),
                            tooltip: '編集',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 22, color: AppTheme.error),
                            onPressed: () => _confirmDeleteStaff(staff),
                            tooltip: '削除',
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addStaff,
        child: const Icon(Icons.person_add_rounded),
      ),
    );
  }
}
