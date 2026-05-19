import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../types.dart';

class StorageService {
  static const String _receiptsKey = 'receipt_app_pro_v5_data';
  static const String _galleryKey = 'receipt_app_gallery_v5';

  static Future<List<Receipt>> getAllReceipts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_receiptsKey);
    if (data == null) return [];
    final parsed = jsonDecode(data);
    return (parsed['receipts'] as List).map((e) => Receipt.fromJson(e)).toList();
  }

  static Future<void> saveReceipts(List<Receipt> receipts, double monthlyBudget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_receiptsKey, jsonEncode({
      'receipts': receipts.map((e) => e.toJson()).toList(),
      'monthlyBudget': monthlyBudget,
    }));
  }

  static Future<double> getMonthlyBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_receiptsKey);
    if (data == null) return 20000;
    final parsed = jsonDecode(data);
    return parsed['monthlyBudget'] ?? 20000;
  }

  static Future<List<GalleryImage>> getAllGalleryImages() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_galleryKey);
    if (data == null) return [];
    return (jsonDecode(data) as List).map((e) => GalleryImage.fromJson(e)).toList();
  }

  static Future<void> saveGalleryImage(GalleryImage image) async {
    final images = await getAllGalleryImages();
    final existingIndex = images.indexWhere((img) => img.id == image.id);
    if (existingIndex >= 0) {
      images[existingIndex] = image;
    } else {
      images.insert(0, image);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_galleryKey, jsonEncode(images.map((e) => e.toJson()).toList()));
  }

  static Future<void> deleteGalleryImage(String id) async {
    final images = await getAllGalleryImages();
    images.removeWhere((img) => img.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_galleryKey, jsonEncode(images.map((e) => e.toJson()).toList()));
  }
}