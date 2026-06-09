import 'package:http/http.dart' as http;
import 'dart:convert';
import 'storage_service.dart';

class ApiService {
  // Use http://localhost:3005/api for Emulator / USB debugging with adb reverse
  // static const String baseUrl = 'http://localhost:3005/api';
  
  // Use Laptop's Wi-Fi IP (both laptop and phone must be on the same Wi-Fi)
  static const String baseUrl = 'http://192.168.8.111:3005/api';

  static Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json',
    };

    if (requiresAuth) {
      final token = await StorageService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    try {
      late http.Response response;

      switch (method) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(url, headers: headers, body: jsonEncode(body));
          break;
        case 'PUT':
          response = await http.put(url, headers: headers, body: jsonEncode(body));
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('Invalid HTTP method');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isNotEmpty) {
          return jsonDecode(response.body);
        }
        return {};
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('error')) {
            throw Exception(errorBody['error']);
          }
        } catch (_) {}
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().startsWith('Exception:')) {
        rethrow;
      }
      throw Exception('Request failed: $e');
    }
  }

  // Authentication
  static Future<void> register(String name, String email, String password) async {
    final response = await _makeRequest(
      'POST',
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
      },
      requiresAuth: false,
    );
    await StorageService.saveToken(response['token']);
  }

  static Future<void> login(String email, String password) async {
    final response = await _makeRequest(
      'POST',
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
      requiresAuth: false,
    );
    await StorageService.saveToken(response['token']);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    return await _makeRequest('GET', '/auth/profile');
  }

  static Future<void> updateProfile({String? name, double? monthlyBudget}) async {
    await _makeRequest(
      'PUT',
      '/auth/profile',
      body: {
        if (name != null) 'name': name,
        if (monthlyBudget != null) 'monthlyBudget': monthlyBudget,
      },
    );
  }

  // Receipts
  static Future<Map<String, dynamic>> analyzeReceipt(String imageData) async {
    return await _makeRequest(
      'POST',
      '/receipts/analyze',
      body: {
        'imageData': imageData, // Base64 encoded image
      },
    );
  }

  static Future<List<dynamic>> getAllReceipts({
    String? month,
    String? category,
    int skip = 0,
    int limit = 20,
  }) async {
    String query = '';
    final params = <String, String>{};
    
    if (month != null) params['month'] = month;
    if (category != null) params['category'] = category;
    params['skip'] = skip.toString();
    params['limit'] = limit.toString();

    if (params.isNotEmpty) {
      query = '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }

    final response = await _makeRequest('GET', '/receipts$query');
    return response['receipts'];
  }

  static Future<void> updateReceipt(
    String id, {
    String? category,
    List<String>? tags,
    String? notes,
  }) async {
    await _makeRequest(
      'PUT',
      '/receipts/$id',
      body: {
        if (category != null) 'category': category,
        if (tags != null) 'tags': tags,
        if (notes != null) 'notes': notes,
      },
    );
  }

  static Future<void> deleteReceipt(String id) async {
    await _makeRequest('DELETE', '/receipts/$id');
  }

  static Future<Map<String, dynamic>> createReceipt({
    required String storeName,
    required double total,
    required String date,
    required String category,
    required String rawText,
    int? timestamp,
  }) async {
    return await _makeRequest(
      'POST',
      '/receipts',
      body: {
        'storeName': storeName,
        'total': total,
        'date': date,
        'category': category,
        'rawText': rawText,
        'timestamp': timestamp ?? DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Gallery
  static Future<Map<String, dynamic>> uploadImage(String imageData, {String? receiptId}) async {
    return await _makeRequest(
      'POST',
      '/gallery/upload',
      body: {
        'imageData': imageData, // Base64 encoded
        if (receiptId != null) 'receiptId': receiptId,
      },
    );
  }

  static Future<List<dynamic>> getGalleryImages({int skip = 0, int limit = 20}) async {
    final response = await _makeRequest(
      'GET',
      '/gallery?skip=$skip&limit=$limit',
    );
    return response['images'];
  }

  static Future<void> deleteGalleryImage(String id) async {
    await _makeRequest('DELETE', '/gallery/$id');
  }

  // Budget
  static Future<Map<String, dynamic>> getBudget(String month) async {
    return await _makeRequest('GET', '/budget/$month');
  }

  static Future<void> updateBudget(String month, double budget) async {
    await _makeRequest(
      'PUT',
      '/budget/$month',
      body: {'budget': budget},
    );
  }

  static Future<Map<String, dynamic>> getSpendingBreakdown(String month) async {
    return await _makeRequest('GET', '/budget/$month/breakdown');
  }

  // Analytics
  static Future<List<dynamic>> getSpendingTrends({int months = 6}) async {
    final response = await _makeRequest('GET', '/analytics/trends?months=$months');
    return response as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getCategoryInsights({String? month}) async {
    String query = month != null ? '?month=$month' : '';
    return await _makeRequest('GET', '/analytics/insights/categories$query');
  }

  static Future<List<dynamic>> getTopStores({int limit = 10, String? month}) async {
    String query = '?limit=$limit';
    if (month != null) query += '&month=$month';
    final response = await _makeRequest('GET', '/analytics/insights/top-stores$query');
    return response as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getBudgetHealth({String? month}) async {
    String query = month != null ? '?month=$month' : '';
    return await _makeRequest('GET', '/analytics/insights/budget-health$query');
  }

  // Social
  static Future<void> shareReceipt(String receiptId, {String? description, String? visibility}) async {
    await _makeRequest(
      'POST',
      '/social/share',
      body: {
        'receiptId': receiptId,
        if (description != null) 'description': description,
        if (visibility != null) 'visibility': visibility,
      },
    );
  }

  static Future<List<dynamic>> getSocialFeed() async {
    final response = await _makeRequest('GET', '/social/feed');
    return response as List<dynamic>;
  }

  static Future<void> likeShare(String shareId) async {
    await _makeRequest('POST', '/social/$shareId/like');
  }

  static Future<void> commentOnShare(String shareId, String text) async {
    await _makeRequest(
      'POST',
      '/social/$shareId/comment',
      body: {'text': text},
    );
  }

  static Future<void> followUser(String userId) async {
    await _makeRequest('POST', '/social/users/$userId/follow');
  }

  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    return await _makeRequest('GET', '/social/users/$userId');
  }
}
