import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/goal_templates.dart';


class FacilityRegisterScreen extends StatefulWidget {
  const FacilityRegisterScreen({super.key});

  @override
  State<FacilityRegisterScreen> createState() => _FacilityRegisterScreenState();
}

class _FacilityRegisterScreenState extends State<FacilityRegisterScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedTemplate = GoalTemplates.afterSchool;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _error;
  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateStep0() {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = '施設名を入力してください');
      return false;
    }
    setState(() => _error = null);
    return true;
  }

  bool _validateStep1() {
    if (_passwordController.text.isEmpty) {
      setState(() => _error = 'パスワードを入力してください');
      return false;
    }
    if (_passwordController.text.length < 4) {
      setState(() => _error = 'パスワードは4文字以上にしてください');
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'パスワードが一致しません');
      return false;
    }
    setState(() => _error = null);
    return true;
  }

  void _nextStep() {
    if (_currentStep == 0 && _validateStep0()) {
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1 && _validateStep1()) {
      setState(() => _currentStep = 2);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
        _error = null;
      });
    }
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = context.read<AppProvider>();

      // 1. 施設を作成
      final facility = await provider.db.createFacility(
        _nameController.text.trim(),
        _passwordController.text,
      );

      // 2. テンプレートの評価項目を追加
      if (_selectedTemplate != GoalTemplates.custom) {
        await provider.db.applyGoalTemplate(
          facility.facilityId,
          _selectedTemplate,
        );
      }

      // 3. 作成した施設にログイン
      provider.login(facility.facilityId, _passwordController.text);

      setState(() => _isLoading = false);

      if (mounted) {
        // 登録成功メッセージ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '「${_nameController.text.trim()}」を登録しました',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        // AppGate will detect login state change and show StaffSelectScreen
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = '登録に失敗しました。もう一度お試しください。';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新しい施設を登録'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step indicator
            _StepIndicator(currentStep: _currentStep),
            const SizedBox(height: 8),

            // Step content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _currentStep == 0
                      ? _buildStep0()
                      : _currentStep == 1
                          ? _buildStep1()
                          : _buildStep2(),
                ),
              ),
            ),

            // Error message
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: AppTheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style:
                              TextStyle(color: AppTheme.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _prevStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('戻る'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : _currentStep < 2
                                ? _nextStep
                                : _register,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _currentStep < 2 ? '次へ' : '施設を登録する',
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 0: 施設名入力
  Widget _buildStep0() {
    return Column(
      key: const ValueKey('step0'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.lightGreen,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business_rounded,
                    color: AppTheme.primaryGreen, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STEP 1: 施設情報',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '施設の名前を入力してください',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '施設名',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '例: ひまわり学童クラブ',
            prefixIcon: Icon(Icons.edit_rounded),
          ),
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _nextStep(),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.lightBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '施設名はログイン画面の施設選択リストに表示されます。',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Step 1: パスワード設定
  Widget _buildStep1() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.lightBlue,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lock_rounded,
                    color: AppTheme.primaryBlue, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STEP 2: パスワード設定',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '施設の共通パスワードを設定してください',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '共通パスワード',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: '4文字以上のパスワード',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.textSecondary,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'パスワード確認',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            hintText: 'もう一度入力してください',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.textSecondary,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          onSubmitted: (_) => _nextStep(),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.beige,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.people_outline, color: AppTheme.softOrange, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'このパスワードは施設のスタッフ全員が共通で使用します。',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Step 2: テンプレート選択
  Widget _buildStep2() {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E5F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.library_books_rounded,
                    color: AppTheme.softPurple, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STEP 3: 評価項目テンプレート',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.softPurple,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '初期の評価項目を選んでください',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Template options
        ...GoalTemplates.templateNames.map((name) {
          final isSelected = _selectedTemplate == name;
          final templates = GoalTemplates.getTemplate(name);
          final isCustom = name == GoalTemplates.custom;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: isSelected
                    ? const BorderSide(color: AppTheme.primaryGreen, width: 2)
                    : BorderSide.none,
              ),
              child: InkWell(
                onTap: () => setState(() => _selectedTemplate = name),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppTheme.primaryGreen
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryGreen
                                    : AppTheme.divider,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 16)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppTheme.primaryGreen
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (!isCustom)
                            Text(
                              '${templates.length}項目',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      if (!isCustom && isSelected) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        ...templates.map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppTheme.getGoalColor(t.color)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Icon(
                                      AppTheme.getGoalIcon(t.icon),
                                      color: AppTheme.getGoalColor(t.color),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.title,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          t.description,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                      if (isCustom) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 36),
                          child: Text(
                            'テンプレートなし（後から自由に追加できます）',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }),

        // Registration summary
        const SizedBox(height: 16),
        Card(
          color: AppTheme.lightGreen,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '登録内容の確認',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _SummaryRow(
                  label: '施設名',
                  value: _nameController.text.trim().isNotEmpty
                      ? _nameController.text.trim()
                      : '---',
                ),
                const SizedBox(height: 6),
                const _SummaryRow(label: 'パスワード', value: '****（設定済み）'),
                const SizedBox(height: 6),
                _SummaryRow(label: 'テンプレート', value: _selectedTemplate),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Row(
        children: [
          _StepDot(
              label: '施設情報', isActive: currentStep >= 0, stepNumber: 1),
          Expanded(child: _StepLine(isActive: currentStep >= 1)),
          _StepDot(
              label: 'パスワード', isActive: currentStep >= 1, stepNumber: 2),
          Expanded(child: _StepLine(isActive: currentStep >= 2)),
          _StepDot(
              label: 'テンプレート', isActive: currentStep >= 2, stepNumber: 3),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final String label;
  final bool isActive;
  final int stepNumber;

  const _StepDot({
    required this.label,
    required this.isActive,
    required this.stepNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppTheme.primaryGreen : AppTheme.divider,
          ),
          child: Center(
            child: Text(
              '$stepNumber',
              style: TextStyle(
                color: isActive ? Colors.white : AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? AppTheme.primaryGreen : AppTheme.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool isActive;

  const _StepLine({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isActive ? AppTheme.primaryGreen : AppTheme.divider,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ),
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
