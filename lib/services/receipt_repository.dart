import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/storage_service.dart';
import '../types.dart';

/// A repository layer that orchestrates data persistence between local storage
/// ([StorageService]) and cloud storage ([FirebaseFirestore]).
/// 
/// Currently uses a local-first synchronization strategy.
class ReceiptRepository {
  /// Loads all locally cached receipts.
  static Future<List<Receipt>> loadReceipts() => StorageService.getAllReceipts();

  /// Loads the user's monthly budget from local cache.
  static Future<double> loadMonthlyBudget() => StorageService.getMonthlyBudget();

  /// Loads all gallery (Vault) images from local cache.
  static Future<List<GalleryImage>> loadGalleryImages() => StorageService.getAllGalleryImages();

  /// Overwrites the locally cached receipts and budget with new lists/values.
  static Future<void> saveReceipts(List<Receipt> receipts, double monthlyBudget) =>
      StorageService.saveReceipts(receipts, monthlyBudget);

  /// Saves or updates a single gallery image in local cache.
  static Future<void> saveGalleryImage(GalleryImage image) =>
      StorageService.saveGalleryImage(image);

  /// Deletes a gallery image from local cache.
  static Future<void> deleteGalleryImage(String id) =>
      StorageService.deleteGalleryImage(id);

  /// Adds a new [receipt] to the system.
  /// 
  /// 1. Prepends the receipt to [currentReceipts].
  /// 2. Saves the updated list locally.
  /// 3. Attempts to publish the receipt to Firestore.
  /// 4. If successful, updates the local record with the generated [firestoreId].
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

  /// Internal helper to push a receipt record to Firestore.
  /// Returns the generated Firestore Document ID on success, or null on failure.
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
