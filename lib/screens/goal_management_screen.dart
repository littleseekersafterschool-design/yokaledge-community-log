import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/goal.dart';
import '../utils/app_theme.dart';
import '../utils/goal_templates.dart';

class GoalManagementScreen extends StatefulWidget {
  const GoalManagementScreen({super.key});

  @override
  State<GoalManagementScreen> createState() => _GoalManagementScreenState();
}

class _GoalManagementScreenState extends State<GoalManagementScreen> {
  void _showAddGoalDialog() {
    final titleC = TextEditingController();
    final descC = TextEditingController();
    String category = AppTheme.goalCategories.first;
    String icon = 'star';
    String color = 'green';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('評価項目を追加'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleC,
                  decoration: const InputDecoration(
                    labelText: '項目名',
                    hintText: '例: 主体性の尊重',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descC,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '説明',
                    hintText: '例: こどもが自分で決める場面を支えられたか',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('カテゴリ',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: AppTheme.goalCategories.map((c) {
                    return ChoiceChip(
                      label: Text(c, style: const TextStyle(fontSize: 12)),
                      selected: category == c,
                      selectedColor:
                          AppTheme.primaryGreen.withValues(alpha: 0.2),
                      onSelected: (v) {
                        if (v) setDialogState(() => category = c);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('アイコン',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppTheme.availableIcons.map((ic) {
                    final isSelected = icon == ic['name'];
                    return GestureDetector(
                      onTap: () =>
                          setDialogState(() => icon = ic['name']!),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                              : AppTheme.background,
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected
                              ? Border.all(
                                  color: AppTheme.primaryGreen, width: 2)
                              : null,
                        ),
                        child: Icon(
                          AppTheme.getGoalIcon(ic['name']!),
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : AppTheme.textSecondary,
                          size: 22,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('色',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppTheme.availableColors.map((c) {
                    final isSelected = color == c;
                    return GestureDetector(
                      onTap: () => setDialogState(() => color = c),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.getGoalColor(c),
                          borderRadius: BorderRadius.circular(18),
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.getGoalColor(c)
                                        .withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  )
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleC.text.trim().isEmpty) return;
                final provider = context.read<AppProvider>();
                final goals = provider.allGoals;
                final goal = Goal(
                  goalId: provider.generateId(),
                  facilityId: provider.currentFacility!.facilityId,
                  title: titleC.text.trim(),
                  description: descC.text.trim(),
                  category: category,
                  icon: icon,
                  color: color,
                  displayOrder: goals.length,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                await provider.addGoal(goal);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('追加'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteGoal(Goal goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('評価項目を削除'),
        content: Text(
          '「${goal.title}」を削除しますか？\n\nこの項目に関連する全ての評価記録も削除されます。この操作は取り消せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              await context.read<AppProvider>().deleteGoal(goal.goalId);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${goal.title}を削除しました'),
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

  void _showEditGoalDialog(Goal goal) {
    final titleC = TextEditingController(text: goal.title);
    final descC = TextEditingController(text: goal.description);
    String category = goal.category;
    String icon = goal.icon;
    String color = goal.color;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('評価項目を編集'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleC,
                  decoration: const InputDecoration(labelText: '項目名'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descC,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: '説明'),
                ),
                const SizedBox(height: 16),
                const Text('カテゴリ',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: AppTheme.goalCategories.map((c) {
                    return ChoiceChip(
                      label: Text(c, style: const TextStyle(fontSize: 12)),
                      selected: category == c,
                      selectedColor:
                          AppTheme.primaryGreen.withValues(alpha: 0.2),
                      onSelected: (v) {
                        if (v) setDialogState(() => category = c);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('アイコン',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppTheme.availableIcons.map((ic) {
                    final isSelected = icon == ic['name'];
                    return GestureDetector(
                      onTap: () =>
                          setDialogState(() => icon = ic['name']!),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                              : AppTheme.background,
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected
                              ? Border.all(
                                  color: AppTheme.primaryGreen, width: 2)
                              : null,
                        ),
                        child: Icon(
                          AppTheme.getGoalIcon(ic['name']!),
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : AppTheme.textSecondary,
                          size: 22,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('色',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppTheme.availableColors.map((c) {
                    final isSelected = color == c;
                    return GestureDetector(
                      onTap: () => setDialogState(() => color = c),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.getGoalColor(c),
                          borderRadius: BorderRadius.circular(18),
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.getGoalColor(c)
                                        .withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  )
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleC.text.trim().isEmpty) return;
                final updated = goal.copyWith(
                  title: titleC.text.trim(),
                  description: descC.text.trim(),
                  category: category,
                  icon: icon,
                  color: color,
                );
                await context.read<AppProvider>().updateGoal(updated);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTemplateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('テンプレートから追加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: GoalTemplates.templateNames
              .where((n) => n != GoalTemplates.custom)
              .map((name) {
            final templates = GoalTemplates.getTemplate(name);
            return ListTile(
              leading: const Icon(Icons.library_add_rounded,
                  color: AppTheme.primaryGreen),
              title: Text(name),
              subtitle: Text('${templates.length}項目',
                  style: const TextStyle(fontSize: 12)),
              onTap: () async {
                await context.read<AppProvider>().applyTemplate(name);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$nameを追加しました'),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final goals = provider.allGoals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('評価項目管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_add_rounded),
            onPressed: _showTemplateDialog,
            tooltip: 'テンプレートから追加',
          ),
        ],
      ),
      body: goals.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.playlist_add_rounded,
                      size: 64, color: AppTheme.divider),
                  const SizedBox(height: 16),
                  const Text(
                    '評価項目がありません',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showTemplateDialog,
                    icon: const Icon(Icons.library_add_rounded),
                    label: const Text('テンプレートから追加'),
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: goals.length,
              onReorder: (oldIndex, newIndex) async {
                if (newIndex > oldIndex) newIndex -= 1;
                final goal = goals[oldIndex];
                final updated = goal.copyWith(displayOrder: newIndex);
                await provider.updateGoal(updated);

                // Update all display orders
                for (var i = 0; i < goals.length; i++) {
                  if (goals[i].goalId != goal.goalId) {
                    final order = i >= newIndex && i <= oldIndex
                        ? i + 1
                        : i <= newIndex && i >= oldIndex
                            ? i - 1
                            : i;
                    await provider.updateGoal(
                        goals[i].copyWith(displayOrder: order));
                  }
                }
              },
              itemBuilder: (context, index) {
                final goal = goals[index];
                final color = AppTheme.getGoalColor(goal.color);
                final iconData = AppTheme.getGoalIcon(goal.icon);

                return Card(
                  key: ValueKey(goal.goalId),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Opacity(
                    opacity: goal.isActive ? 1.0 : 0.5,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(iconData, color: color, size: 22),
                      ),
                      title: Text(
                        goal.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${goal.category}  ${goal.description}',
                        style: const TextStyle(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              goal.isActive
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: 20,
                              color: goal.isActive
                                  ? AppTheme.primaryGreen
                                  : AppTheme.textSecondary,
                            ),
                            onPressed: () async {
                              await provider.updateGoal(
                                goal.copyWith(isActive: !goal.isActive),
                              );
                            },
                            tooltip: goal.isActive ? '非表示にする' : '表示する',
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 20),
                            onPressed: () => _showEditGoalDialog(goal),
                            tooltip: '編集',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 20, color: AppTheme.error),
                            onPressed: () => _confirmDeleteGoal(goal),
                            tooltip: '削除',
                          ),
                          const Icon(Icons.drag_handle_rounded,
                              color: AppTheme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
