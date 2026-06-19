import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import 'dashboard_screen.dart';
import 'evaluation_input_screen.dart';
import 'calendar_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _pages = [
    DashboardScreen(),
    EvaluationInputScreen(),
    CalendarScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  static const _titles = [
    'ダッシュボード',
    '今日の評価',
    'カレンダー',
    '評価履歴',
    '設定',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final facility = provider.currentFacility;
    final staff = provider.currentStaff;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        leading: Padding(
          padding: const EdgeInsets.all(6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        leadingWidth: 44,
        actions: [
          if (staff != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        AppTheme.primaryGreen.withValues(alpha: 0.15),
                    child: Text(
                      staff.staffName.isNotEmpty ? staff.staffName[0] : '?',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    staff.staffName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
        bottom: facility != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: AppTheme.divider,
                ),
              )
            : null,
      ),
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note_rounded),
            label: '評価入力',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'カレンダー',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: '履歴',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: '設定',
          ),
        ],
      ),
    );
  }
}
