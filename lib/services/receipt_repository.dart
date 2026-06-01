import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../services/storage_service.dart';
import '../types.dart';

class ReceiptRepository {
  static Future<List<Receipt>> loadReceipts() => StorageService.getAllReceipts();

  static Future<double> loadMonthlyBudget() => StorageService.getMonthlyBudget();

  static Future<List<GalleryImage>> loadGalleryImages() => StorageService.getAllGalleryImages();

  static Future<void> saveReceipts(List<Receipt> receipts, double monthlyBudget) =>
      StorageService.saveReceipts(receipts, monthlyBudget);

  static Future<void> saveGalleryImage(GalleryImage image) =>
      StorageService.saveGalleryImage(image);

  static Future<void> deleteGalleryImage(String id) =>
      StorageService.deleteGalleryImage(id);

  static Future<void> addReceipt(
    Receipt receipt,
    List<Receipt> currentReceipts,
    double monthlyBudget,
  ) async {
    final updatedReceipts = [receipt, ...currentReceipts];
    await saveReceipts(updatedReceipts, monthlyBudget);
    final docId = await _publishReceiptToBackend(receipt);
    if (docId != null) {
      receipt.firestoreId = docId;
      await saveReceipts(updatedReceipts, monthlyBudget);
    }
  }

  static Future<String?> _publishReceiptToBackend(Receipt receipt) async {
    try {
      final response = await ApiService.createReceipt(
        storeName: receipt.storeName,
        total: receipt.total,
        date: receipt.date,
        category: receipt.category.name,
        rawText: receipt.rawText ?? '',
        timestamp: receipt.timestamp,
      );
      return response['_id'] ?? response['id']?.toString();
    } catch (e) {
      debugPrint('Failed to save receipt to MongoDB backend: $e');
      return null;
    }
  }
}
