import 'package:cloud_firestore/cloud_firestore.dart';

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
    await _publishReceiptToFirestore(receipt);
  }

  static Future<void> _publishReceiptToFirestore(Receipt receipt) async {
    await FirebaseFirestore.instance.collection('receipts').add({
      'storeName': receipt.storeName,
      'totalAmount': receipt.total,
      'date': receipt.date,
      'time': receipt.time,
      'category': receipt.category.name,
      'rawText': receipt.rawText ?? '',
      'items': receipt.items.map((item) => item.toJson()).toList(),
      'timestamp': receipt.timestamp,
    });
  }
}
