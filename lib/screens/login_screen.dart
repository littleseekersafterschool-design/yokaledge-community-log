import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import 'facility_register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? _selectedFacilityId;
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_selectedFacilityId == null) {
      setState(() => _error = '施設を選択してください');
      return;
    }
    if (_passwordController.text.isEmpty) {
      setState(() => _error = 'パスワードを入力してください');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final provider = context.read<AppProvider>();
    final success =
        provider.login(_selectedFacilityId!, _passwordController.text);

    setState(() => _isLoading = false);

    if (success) {
      // AppGate will automatically switch to StaffSelectScreen
      // because provider.isLoggedIn is now true
    } else {
      setState(() => _error = 'パスワードが正しくありません');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final facilities = provider.facilities;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo
                Image.asset(
                  'assets/images/logo.png',
                  width: 260,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreen,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        size: 56,
                        color: AppTheme.primaryGreen,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'コミュニティスコア',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 32),

                // Facility selection
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.business_rounded,
                                color: AppTheme.primaryGreen, size: 22),
                            const SizedBox(width: 8),
                            const Text(
                              '施設を選択',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.divider),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedFacilityId,
                              hint: const Text('施設を選んでください'),
                              items: facilities
                                  .map((f) => DropdownMenuItem(
                                        value: f.facilityId,
                                        child: Text(f.facilityName),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedFacilityId = v),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Icon(Icons.lock_outline_rounded,
                                color: AppTheme.primaryGreen, size: 22),
                            const SizedBox(width: 8),
                            const Text(
                              '共通パスワード',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'パスワードを入力',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppTheme.textSecondary,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          onSubmitted: (_) => _login(),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: AppTheme.error, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: TextStyle(
                                      color: AppTheme.error,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('ログイン',
                                    style: TextStyle(fontSize: 17)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 新規施設登録ボタン
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                const FacilityRegisterScreen()),
                      );
                    },
                    icon: const Icon(Icons.add_business_rounded),
                    label: const Text('新しい施設を登録する'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                      side: const BorderSide(color: AppTheme.primaryGreen),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
