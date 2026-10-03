import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'your_key',
  );
  static const _model = 'gemini-3.5-flash-lite';
  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  Future<String> generateText(String prompt) async {
    if (_apiKey.isEmpty) {
      throw Exception('กรุณากำหนด GEMINI_API_KEY ผ่าน --dart-define=GEMINI_API_KEY=your_key');
    }

    final uri = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ]
    });

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final candidates = data['candidates'] as List<dynamic>?;

        if (candidates == null || candidates.isEmpty) {
          throw Exception('AI ไม่สามารถให้คำตอบได้ หรือถูกบล็อกด้วยระบบความปลอดภัย');
        }

        final firstCandidate = candidates[0] as Map<String, dynamic>;

        final finishReason = firstCandidate['finishReason'] as String?;
        if (finishReason == 'SAFETY') {
          throw Exception('เนื้อหาถูกบล็อกด้วยระบบความปลอดภัย (SAFETY)');
        }

        final content = firstCandidate['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;

        if (parts == null || parts.isEmpty) {
          throw Exception('ไม่พบเนื้อหาข้อความในคำตอบจาก AI');
        }

        final text = parts[0]['text'] as String?;
        return text ?? '';
      }

      throw Exception('เกิดข้อผิดพลาดจาก Gemini API (สถานะ ${response.statusCode})');
    } on TimeoutException {
      throw Exception('การเชื่อมต่อหมดเวลา (เกิน 20 วินาที) กรุณาลองใหม่อีกครั้ง');
    } on http.ClientException {
      throw Exception('ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบการเชื่อมต่อ');
    } on FormatException {
      throw Exception('ข้อมูลที่ได้รับจากเซิร์ฟเวอร์ไม่ถูกต้อง');
    } catch (e) {
      rethrow;
    }
  }
}
