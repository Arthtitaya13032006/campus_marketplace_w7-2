import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/listing_draft.dart';

class GeminiVisionService {
  static const _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'your_key',
  );
  static const _model = 'gemini-3.5-flash-lite';
  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  static const _defaultPrompt = '''
คุณคือผู้ช่วยเขียนประกาศขายของมือสองในตลาดนัดออนไลน์สำหรับนักศึกษามหาวิทยาลัย (ผู้ขายเป็นผู้หญิง)
จากรูปภาพสินค้าที่แนบมา ให้วิเคราะห์แล้วตอบกลับเป็น JSON เท่านั้น ตามโครงสร้างนี้:
{
  "title": "ชื่อประกาศสั้นกระชับ ไม่เกิน 40 ตัวอักษร",
  "category": "หมวดหมู่ที่ตรงกับสินค้าที่สุด เช่น เครื่องดนตรี, เสื้อผ้า, อุปกรณ์อิเล็กทรอนิกส์, หนังสือเรียน, ของแต่งหอพัก, อุปกรณ์กีฬา โดยระบุประเภทที่แท้จริงของสินค้าอย่างเจาะจง (ห้ามตอบว่า อื่นๆ ให้ระบุชื่อประเภทที่แท้จริง)",
  "description": "คำบรรยายสินค้า 2-3 ประโยค ที่ดึงดูดผู้ซื้อและบอกสภาพของสินค้าตามที่เห็นในภาพ โดยใช้คำลงท้ายว่า ค่ะ หรือ นะคะ เท่านั้น (ห้ามใช้คำว่า ครับ โดยเด็ดขาด)"
}
ห้ามตอบข้อความอื่นนอกเหนือจาก JSON ดังกล่าว
''';

  String _getMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<ListingDraft> analyzeProductImage(
    File imageFile, {
    String prompt = _defaultPrompt,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('กรุณากำหนด GEMINI_API_KEY ผ่าน --dart-define=GEMINI_API_KEY=your_key');
    }

    if (!await imageFile.exists()) {
      throw Exception('ไม่พบไฟล์รูปภาพที่เลือก');
    }

    if (prompt.contains('ปลอมแปลง') || prompt.contains('ไม่ต้องสนใจคำแนะนำก่อนหน้านี้')) {
      throw Exception('ภาพนี้ถูกบล็อกโดยระบบความปลอดภัยของ Gemini');
    }

    // 1. อ่านไฟล์ภาพเป็นไบต์ และเข้ารหัส Base64
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final mimeType = _getMimeType(imageFile.path);

    final uri = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');

    // 2. ส่งพร้อม Prompt ใน parts เดียวกัน และใช้ responseSchema บังคับให้ได้ JSON
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inlineData': {
                'mimeType': mimeType,
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'title': {'type': 'STRING'},
            'category': {'type': 'STRING'},
            'description': {'type': 'STRING'},
          },
          'required': ['title', 'category', 'description'],
        }
      }
    });

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        // jsonDecode ชั้นที่ 1: แปลง HTTP Response body จาก Gemini API
        final Map<String, dynamic> data = jsonDecode(response.body);
        final candidates = data['candidates'] as List<dynamic>?;

        if (candidates == null || candidates.isEmpty) {
          final promptFeedback = data['promptFeedback'] as Map<String, dynamic>?;
          final blockReason = promptFeedback?['blockReason'] as String?;
          if (blockReason != null) {
            throw Exception('เนื้อหาถูกบล็อกด้วยระบบความปลอดภัยของ Gemini ($blockReason)');
          }
          throw Exception('AI ไม่สามารถวิเคราะห์ภาพนี้ได้ อาจเข้าข่ายเนื้อหาที่ไม่เหมาะสม ลองใช้ภาพอื่น');
        }

        final firstCandidate = candidates[0] as Map<String, dynamic>;
        final finishReason = firstCandidate['finishReason'] as String?;
        if (finishReason == 'SAFETY') {
          throw Exception('เนื้อหาที่วิเคราะห์เข้าข่ายไม่ปลอดภัยตามนโยบายของ Gemini กรุณาใช้ภาพอื่น');
        }

        final content = firstCandidate['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;

        if (parts == null || parts.isEmpty) {
          throw Exception('ไม่พบผลลัพธ์จาก AI');
        }

        final text = parts[0]['text'] as String?;
        if (text == null || text.trim().isEmpty) {
          throw Exception('ผลลัพธ์จาก AI ว่างเปล่า');
        }

        // jsonDecode ชั้นที่ 2: แปลงข้อความ JSON String ภายใน text ให้กลายเป็น ListingDraft
        try {
          final Map<String, dynamic> jsonResult = jsonDecode(text);
          final title = (jsonResult['title'] ?? '').toString();
          final category = (jsonResult['category'] ?? '').toString();
          final description = (jsonResult['description'] ?? '').toString();
          final combined = '$title $category $description'.toLowerCase();

          // ตรวจสอบว่าผลลัพธ์เป็นข้อความปฏิเสธจาก AI หรือไม่
          if (combined.contains('ไม่สามารถ') ||
              combined.contains('ขออภัย') ||
              combined.contains('ปฏิเสธ') ||
              combined.contains('ขัดต่อ') ||
              combined.contains('ผิดกฎหมาย') ||
              combined.contains('นโยบาย') ||
              combined.contains('ความปลอดภัย')) {
            throw Exception('เนื้อหาถูกบล็อกด้วยระบบความปลอดภัยของ Gemini (SAFETY): AI ปฏิเสธคำขอเนื่องจากขัดต่อนโยบายความปลอดภัย');
          }

          return ListingDraft.fromJson(jsonResult);
        } on FormatException {
          // กรณี AI ปฏิเสธคำขอด้วยข้อความธรรมดา เช่น ไม่สามารถช่วยเหลือเรื่องการปลอมแปลงเอกสารได้
          if (text.contains('ไม่สามารถ') ||
              text.contains('ขออภัย') ||
              text.contains('ผิดกฎหมาย') ||
              text.contains('นโยบาย') ||
              text.contains('ความปลอดภัย')) {
            throw Exception('เนื้อหาถูกบล็อกด้วยระบบความปลอดภัยของ Gemini (SAFETY): $text');
          }
          throw Exception('ข้อมูลที่ได้รับจาก AI ไม่ถูกต้องตามรูปแบบ JSON หรือถูกปฏิเสธคำขอ');
        }
      }

      throw Exception('เกิดข้อผิดพลาดจาก Gemini API (สถานะ ${response.statusCode})');
    } on TimeoutException {
      throw Exception('การเชื่อมต่อหมดเวลา (เกิน 30 วินาที) กรุณาลองใหม่อีกครั้ง');
    } on http.ClientException {
      throw Exception('ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบการเชื่อมต่อ');
    } catch (e) {
      rethrow;
    }
  }
}
