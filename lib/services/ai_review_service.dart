import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_config.dart';

class AiReviewService {
  const AiReviewService();

  Future<String> generateReport({
    required String facilityName,
    required String periodLabel,
    required List<Map<String, dynamic>> records,
  }) async {
    if (records.isEmpty) {
      return '選択した期間に評価記録がありません。';
    }

    final response = await http.post(
      AppConfig.apiUri('/api/review-report'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'facilityName': facilityName,
        'periodLabel': periodLabel,
        'records': records,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('AIレポート作成に失敗しました: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final report = data['report'];
    if (report is String && report.trim().isNotEmpty) {
      return report.trim();
    }
    throw Exception('AIレポートを取得できませんでした。');
  }
}
