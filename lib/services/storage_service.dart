import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../types.dart';

/// A local persistence service that uses [SharedPreferences] to store and retrieve
/// application data including receipts, gallery images, and the monthly budget.
class StorageService {
  static const String _receiptsKey = 'receipt_app_pro_v5_data';
  static const String _galleryKey = 'receipt_app_gallery_v5';

  /// Retrieves all saved receipts from local storage.
  static Future<List<Receipt>> getAllReceipts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_receiptsKey);
    if (data == null) return [];
    final parsed = jsonDecode(data);
    return (parsed['receipts'] as List).map((e) => Receipt.fromJson(e)).toList();
  }

  /// Saves the complete list of [receipts] and the [monthlyBudget] to local storage.
  /// Overwrites the previously saved data.
  static Future<void> saveReceipts(List<Receipt> receipts, double monthlyBudget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_receiptsKey, jsonEncode({
      'receipts': receipts.map((e) => e.toJson()).toList(),
      'monthlyBudget': monthlyBudget,
    }));
  }

  /// Retrieves the current monthly budget from local storage.
  /// Returns a default value of 20000 if not found.
  static Future<double> getMonthlyBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_receiptsKey);
    if (data == null) return 20000;
    final parsed = jsonDecode(data);
    return parsed['monthlyBudget'] ?? 20000;
  }

  /// Retrieves all saved gallery images (vault items) from local storage.
  static Future<List<GalleryImage>> getAllGalleryImages() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_galleryKey);
    if (data == null) return [];
    return (jsonDecode(data) as List).map((e) => GalleryImage.fromJson(e)).toList();
  }

  /// Saves or updates a single [GalleryImage] in local storage.
  /// If an image with the same [id] exists, it is updated. Otherwise, it is added.
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

  /// Deletes a gallery image from local storage by its [id].
  static Future<void> deleteGalleryImage(String id) async {
    final images = await getAllGalleryImages();
    images.removeWhere((img) => img.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_galleryKey, jsonEncode(images.map((e) => e.toJson()).toList()));
  }
}