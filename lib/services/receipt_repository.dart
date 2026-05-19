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
    final docId = await _publishReceiptToFirestore(receipt);
    if (docId != null) {
      // persist the firestoreId into local storage
      receipt.firestoreId = docId;
      await saveReceipts(updatedReceipts, monthlyBudget);
    }
  }

  static Future<String?> _publishReceiptToFirestore(Receipt receipt) async {
    try {
      final docRef = await FirebaseFirestore.instance.collection('receipts').add({
        'localId': receipt.id,
        'storeName': receipt.storeName,
        'totalAmount': receipt.total,
        'date': receipt.date,
        'time': receipt.time,
        'category': receipt.category.name,
        'rawText': receipt.rawText ?? '',
        'items': receipt.items.map((item) => item.toJson()).toList(),
        'timestamp': receipt.timestamp,
      });
      return docRef.id;
    } catch (e) {
      // Firestore publish failed; leave local data intact and surface the error upstream if needed.
      return null;
    }
  }
}
