import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'utils/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/staff_select_screen.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? firebaseError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw TimeoutException('Firebase初期化が15秒以内に完了しませんでした');
      },
    );
  } catch (e) {
    firebaseError = e.toString();
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: StaffLogApp(firebaseError: firebaseError),
    ),
  );
}

class StaffLogApp extends StatelessWidget {
  final String? firebaseError;
  const StaffLogApp({super.key, this.firebaseError});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'よかレッジ！コミュニティスコア',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: firebaseError != null
          ? _FirebaseErrorScreen(error: firebaseError!)
          : const AppGate(),
    );
  }
}

class _FirebaseErrorScreen extends StatelessWidget {
  final String error;
  const _FirebaseErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 56, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Firebase接続エラー',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(error,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              const Text(
                'このプレビュー環境ではFirebase接続が制限されている場合があります。\n'
                'APK版をインストールしてご利用ください。',
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// AppGate: Providerの状態を監視し、適切な画面を表示するゲートウィジェット。
/// ナビゲーションスタックのルートとして常に存在し、
/// logout()が呼ばれると自動的にLoginScreenに切り替わる。
class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await context.read<AppProvider>().initialize();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 56, color: AppTheme.error),
                const SizedBox(height: 16),
                const Text(
                  '初期化エラー',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _error = null);
                    _init();
                  },
                  child: const Text('再試行'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!provider.isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppTheme.primaryGreen,
              ),
              SizedBox(height: 20),
              Text(
                'よかレッジ！',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'コミュニティスコア',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '読み込み中...',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // --- Core gate logic ---
    if (!provider.isLoggedIn) {
      return const LoginScreen();
    }

    if (!provider.isStaffSelected) {
      return const StaffSelectScreen();
    }

    return const MainShell();
  }
}
