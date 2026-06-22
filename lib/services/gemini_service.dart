import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiService {
  // 🚨 API Key eka frontend eken 100% ain kara!
  // Oya Step 2 eken gaththa IP eka methanata danna (Port eka 3005)
  static const String _backendUrl =
      'http://192.168.8.108:3005/api/receipts/analyze';

  // Backend eke 'authenticate' middleware eka thiyena nisa JWT token ekath yawanna ona
  static Future<Map<String, dynamic>> analyzeReceipt(
    String imagePath,
    String token,
  ) async {
    // 1. Image eka bytes walata aran Base64 walata convert karanawa
    final bytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(bytes);

    // Backend eka balaporoththu wena widihata 'data:image...' kaalla ekathu karanawa
    final imageDataString = 'data:image/jpeg;base64,$base64Image';

    try {
      final response = await http
          .post(
            Uri.parse(_backendUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token', // User ge login token eka
            },
            body: jsonEncode({'imageData': imageDataString}),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Backend eken ewana success response eka
        final body = jsonDecode(response.body);

        // Backend eke 'analysisData' kiyala thama JSON eka ewanne
        return body['analysisData'];
      } else {
        print("Backend Error Body: ${response.body}");
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection Error: $e');
    }
  }

  static Future<Map<String, dynamic>> analyzeTextReceipt(
    String rawText,
    String token,
  ) async {
    const String analyzeTextUrl =
        'http://192.168.8.108:3005/api/receipts/analyze-text';

    try {
      final response = await http
          .post(
            Uri.parse(analyzeTextUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'text': rawText}),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['analysisData'];
      } else {
        print("Backend Error Body: ${response.body}");
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection Error: $e');
    }
  }
}
