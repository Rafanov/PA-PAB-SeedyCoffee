import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/env_config.dart';

class AiService {
  AiService._();
  static final AiService instance = AiService._();

  Future<AiInsight> generateInsight(Map<String, dynamic> data) async {
    if (!EnvConfig.useGemini) return _placeholderInsight();
    try {
      return await _callGemini(data);
    } catch (e) {
      debugPrint('Gemini error: $e');
      return _errorInsight(e.toString());
    }
  }

  Future<AiInsight> _callGemini(Map<String, dynamic> data) async {
    // gemini-2.5-flash with thinkingBudget=0 disables thinking tokens
    // so it returns clean text response
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      'gemini-2.5-flash:generateContent?key=${EnvConfig.geminiApiKey}',
    );

    final body = jsonEncode({
      'contents': [
        {
          'parts': [{'text': _buildPrompt(data)}]
        }
      ],
      'generationConfig': {
        'temperature': 0.3,
        'maxOutputTokens': 1024,
        // Disable thinking for cleaner JSON output
        'thinkingConfig': {'thinkingBudget': 0},
      },
    });

    final response = await http
        .post(url,
            headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 429) {
      throw Exception('Quota exceeded — try again in a moment');
    }
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final respBody = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = respBody['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No response from Gemini');
    }

    // gemini-2.5-flash may have multiple parts (thinking + response)
    // Get text from ALL parts and concatenate
    final parts = candidates[0]['content']['parts'] as List? ?? [];
    final fullText = parts
        .map((p) => (p['text'] as String? ?? ''))
        .join('\n');

    debugPrint('Gemini raw (first 200): ${fullText.substring(0, fullText.length.clamp(0, 200))}');

    return _parseInsight(fullText);
  }

  AiInsight _parseInsight(String text) {
    // Find first { and last } directly — most robust approach
    final start = text.indexOf('{');
    final end   = text.lastIndexOf('}');

    if (start < 0 || end < 0 || end <= start) {
      debugPrint('Gemini: no JSON braces found in: ' + text.substring(0, text.length.clamp(0, 100)));
      throw Exception('No JSON found in response');
    }

    final jsonStr = text.substring(start, end + 1);
    debugPrint('Gemini: parsing JSON of length ' + jsonStr.length.toString());

    final j = jsonDecode(jsonStr) as Map<String, dynamic>;

    return AiInsight(
      summary:         j['summary']?.toString()         ?? '',
      highlights:      _toList(j['highlights']),
      recommendations: _toList(j['recommendations']),
      prediction:      j['prediction']?.toString()      ?? '',
      sentiment:       j['sentiment']?.toString()       ?? 'neutral',
    );
  }

  List<String> _toList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    return [v.toString()];
  }

  String _buildPrompt(Map<String, dynamic> data) =>
    'Kamu analis bisnis coffee shop "SeedyCoffee". '
    'Analisis data ini:\n${jsonEncode(data)}\n\n'
    'PENTING: Balas HANYA dengan JSON ini (tidak ada teks lain):\n'
    '{"summary":"ringkasan kondisi bisnis 1-2 kalimat",'
    '"highlights":["highlight 1","highlight 2","highlight 3"],'
    '"recommendations":["rekomendasi 1","rekomendasi 2"],'
    '"prediction":"prediksi singkat",'
    '"sentiment":"positive"}';

  AiInsight _placeholderInsight() => const AiInsight(
    summary: 'Tambahkan GEMINI_API_KEY di .env untuk mengaktifkan AI Insight.',
    highlights: [
      'Data penjualan tersedia di ringkasan di atas',
      'Chart menampilkan tren 7 hari terakhir',
      'Top menu berdasarkan jumlah terjual',
    ],
    recommendations: [
      'Isi GEMINI_API_KEY di file .env',
      'Restart dengan --dart-define-from-file=.env',
    ],
    prediction: 'Aktifkan Gemini API untuk prediksi otomatis.',
    sentiment: 'neutral',
  );

  AiInsight _errorInsight(String error) => AiInsight(
    summary: 'AI Insight gagal. Tap 🔄 untuk coba lagi.',
    highlights: [
      'API Key terdeteksi ✓',
      'Model: gemini-2.5-flash',
      'Error: ${error.length > 80 ? error.substring(0, 80) : error}',
    ],
    recommendations: [
      'Cek quota di aistudio.google.com',
      'Tunggu 1 menit jika kena rate limit, lalu refresh',
    ],
    prediction: 'Tap tombol 🔄 untuk mencoba lagi.',
    sentiment: 'neutral',
  );
}

class AiInsight {
  final String summary, prediction, sentiment;
  final List<String> highlights, recommendations;

  const AiInsight({
    required this.summary,
    required this.highlights,
    required this.recommendations,
    required this.prediction,
    required this.sentiment,
  });
}
