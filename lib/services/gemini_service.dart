import 'dart:convert';
import 'package:http/http.dart' as http;
import '../types.dart';

class GeminiService {
  static const String _apiKey = 'YOUR_API_KEY_HERE';

  static Future<Map<String, dynamic>> analyzeReceipt(String base64Image) async {
    final categories = Category.values.map((e) => e.name).join(", ");
    final prompt = '''
You are a high-precision OCR and financial analysis agent. 
TASK:
1. Carefully scan the provided image, which may contain a HANDWRITTEN receipt. The receipt text may be in English, Sinhala, or Tamil languages.
2. Perform deep OCR to extract the Store Name, Date, Total Price, and individual line items (name and price), accurately reading English, Sinhala, and Tamil characters.
3. Handwriting may be messy, slanted, or use non-standard symbols. Infer the most likely text based on context across English, Sinhala, and Tamil.
4. Categorize the entire receipt into exactly ONE of these categories: $categories.
   * Note: If the image is an ATM receipt, bank deposit, bank transfer, or card payment slip, use "BankPayment". If it is an Uber, PickMe, taxi, train, or bus ticket, use "Transport".
5. Categorize EACH INDIVIDUAL ITEM into EXACTLY ONE of the allowed categories: $categories. If an item does not clearly fit into any of these, you MUST use "Other". Do not make up new categories.
6. CURRENCY CONVERSION: Identify the original currency displayed on the receipt. If it is NOT Sri Lankan Rupees (LKR), internally determine the current real-time exchange rate on Google and CONVERT the Total Price and ALL individual item prices strictly into Sri Lankan Rupees (LKR).

CRITICAL INSTRUCTION:
- TRANSLATION MANDATORY: All text output (like storeName, item name, category) MUST be translated to English and returned using ONLY English letters. Do not return any Sinhala or Tamil characters in the JSON output.
- All price and total fields MUST be returned only in LKR. Do not return foreign currency amounts.
- If the image is too blurry, too dark, or does not contain a recognizable receipt with readable text/numbers, set the 'isReadable' field to false.
- Otherwise, set 'isReadable' to true and extract all details.

Return ONLY a valid JSON object following the provided schema, with no markdown code blocks.
''';

    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inlineData': {
                    'mimeType': 'image/jpeg',
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
                'isReadable': {'type': 'BOOLEAN'},
                'storeName': {'type': 'STRING'},
                'date': {'type': 'STRING'},
                'time': {'type': 'STRING'},
                'total': {'type': 'NUMBER'},
                'category': {'type': 'STRING'},
                'items': {
                  'type': 'ARRAY',
                  'items': {
                    'type': 'OBJECT',
                    'properties': {
                      'name': {'type': 'STRING'},
                      'price': {'type': 'NUMBER'},
                      'category': {'type': 'STRING'},
                    },
                    'required': ['name', 'price', 'category']
                  }
                }
              },
              'required': ['isReadable']
            }
          }
        }),
      );

      if (response.statusCode != 200) {
        if (response.statusCode == 429) {
          throw Exception('Rate limit exceeded. Please wait about 15 seconds and try again.');
        }
        throw Exception('Failed to analyze receipt');
      }

      final body = jsonDecode(response.body);
      final text = body['candidates'][0]['content']['parts'][0]['text'] ?? '{}';
      return jsonDecode(text);
    } catch (e) {
      throw Exception('Gemini Analysis Error: $e');
    }
  }
}