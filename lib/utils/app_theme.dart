import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF6BAF7A);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color softGreen = Color(0xFFA5D6A7);
  static const Color primaryBlue = Color(0xFF7BAFD4);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color beige = Color(0xFFF5F0E8);
  static const Color warmWhite = Color(0xFFFAFAF7);
  static const Color softOrange = Color(0xFFFFB74D);
  static const Color softYellow = Color(0xFFFFF176);
  static const Color softPurple = Color(0xFFB39DDB);
  static const Color textPrimary = Color(0xFF37474F);
  static const Color textSecondary = Color(0xFF78909C);
  static const Color cardShadow = Color(0x1A000000);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color error = Color(0xFFE57373);
  static const Color background = Color(0xFFF5F5F0);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: primaryGreen,
        brightness: Brightness.light,
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: cardShadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryGreen, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: primaryGreen,
          unselectedItemColor: textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      );

  static Color getGoalColor(String colorName) {
    switch (colorName) {
      case 'green':
        return primaryGreen;
      case 'blue':
        return primaryBlue;
      case 'orange':
        return softOrange;
      case 'yellow':
        return const Color(0xFFFFC107);
      case 'purple':
        return softPurple;
      case 'red':
        return const Color(0xFFEF5350);
      case 'pink':
        return const Color(0xFFF48FB1);
      case 'teal':
        return const Color(0xFF4DB6AC);
      default:
        return primaryGreen;
    }
  }

  static IconData getGoalIcon(String iconName) {
    switch (iconName) {
      case 'heart':
        return Icons.favorite;
      case 'tree':
        return Icons.park;
      case 'star':
        return Icons.star;
      case 'chat':
        return Icons.chat_bubble;
      case 'safety':
        return Icons.security;
      case 'play':
        return Icons.sports_esports;
      case 'people':
        return Icons.people;
      case 'handshake':
        return Icons.handshake;
      case 'seedling':
        return Icons.eco;
      case 'shield':
        return Icons.shield;
      case 'sun':
        return Icons.wb_sunny;
      case 'book':
        return Icons.menu_book;
      default:
        return Icons.star;
    }
  }

  static Color getScoreColor(double score) {
    if (score >= 4.5) return const Color(0xFF2E7D32);
    if (score >= 3.5) return primaryGreen;
    if (score >= 2.5) return softOrange;
    if (score >= 1.5) return const Color(0xFFFF8A65);
    return error;
  }

  static const List<String> availableColors = [
    'green',
    'blue',
    'orange',
    'yellow',
    'purple',
    'red',
    'pink',
    'teal',
  ];

  static const List<Map<String, String>> availableIcons = [
    {'name': 'seedling', 'label': '芽'},
    {'name': 'heart', 'label': 'ハート'},
    {'name': 'tree', 'label': '木'},
    {'name': 'star', 'label': '星'},
    {'name': 'chat', 'label': '会話'},
    {'name': 'safety', 'label': '安全'},
    {'name': 'play', 'label': '遊び'},
    {'name': 'people', 'label': '人々'},
    {'name': 'handshake', 'label': '連携'},
    {'name': 'shield', 'label': 'シールド'},
    {'name': 'sun', 'label': '太陽'},
    {'name': 'book', 'label': '本'},
  ];

  static const List<String> goalCategories = [
    '保育',
    '安全',
    '関係性',
    '環境',
    'チーム連携',
    '主体性',
    'ウェルビーイング',
  ];
}
