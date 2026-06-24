import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/receipt_processing_service.dart';
import '../services/receipt_repository.dart';
import '../types.dart';

/// The primary ViewModel for the application, managing global state for receipts,
/// gallery images, and the monthly budget.
/// 
/// This class acts as the central coordinator between the UI layer and the service
/// layer (e.g., [ReceiptProcessingService], [ReceiptRepository]). It notifies
/// listeners whenever state changes so the UI can rebuild.
class AppState extends ChangeNotifier {
  /// The list of all processed and saved receipts.
  List<Receipt> receipts = [];

  /// The list of images imported to or captured by the app's gallery (Vault).
  List<GalleryImage> galleryImages = [];

  /// Indicates whether the app is currently running OCR or image processing.
  bool isAnalyzing = false;

  /// Holds any error message resulting from the latest processing attempt, or null if successful.
  String? analysisError;

  /// The user-defined monthly budget limit for expenses. Defaults to 20,000.
  double monthlyBudget = 20000;

  /// Loads all persisted data (receipts, gallery images, budget) from the
  /// repository into memory during application startup.
  Future<void> loadData() async {
    receipts = await ReceiptRepository.loadReceipts();
    galleryImages = await ReceiptRepository.loadGalleryImages();
    monthlyBudget = await ReceiptRepository.loadMonthlyBudget();
    galleryImages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  /// Processes a receipt image at the given [imagePath].
  /// 
  /// This runs the image through the [ReceiptProcessingService] to extract
  /// structured data via OCR, saves the resulting [Receipt] via the repository,
  /// and updates the local state.
  Future<void> processReceipt(String imagePath) async {
    isAnalyzing = true;
    analysisError = null;
    notifyListeners();

    try {
      final receipt = await ReceiptProcessingService.processReceiptImage(imagePath);
      await ReceiptRepository.addReceipt(receipt, receipts, monthlyBudget);
      receipts.insert(0, receipt);
      notifyListeners();
    } catch (e) {
      analysisError = 'Error scanning: $e';
      notifyListeners();
    } finally {
      isAnalyzing = false;
      notifyListeners();
    }
  }

  /// Prompts the user to select an image from the device gallery.
  /// 
  /// Once picked, the image is saved to the local gallery vault, and then
  /// automatically processed to extract receipt data.
  Future<void> pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final galleryImage = GalleryImage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        base64: base64Encode(bytes),
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isProcessed: false,
      );
      galleryImages.insert(0, galleryImage);
      await ReceiptRepository.saveGalleryImage(galleryImage);
      notifyListeners();
      await processReceipt(pickedFile.path);
      // Mark as processed after successful scan
      galleryImage.isProcessed = true;
      await ReceiptRepository.saveGalleryImage(galleryImage);
      notifyListeners();
    }
  }

  /// Deletes a gallery image by its [id] from both state and storage.
  Future<void> deleteGalleryItem(String id) async {
    galleryImages.removeWhere((img) => img.id == id);
    await ReceiptRepository.deleteGalleryImage(id);
    notifyListeners();
  }

  /// Deletes a receipt by its [id] from both state and storage.
  Future<void> deleteReceipt(String id) async {
    receipts.removeWhere((r) => r.id == id);
    await ReceiptRepository.saveReceipts(receipts, monthlyBudget);
    notifyListeners();
  }

  /// Updates the [monthlyBudget] and persists the new value to storage.
  Future<void> updateBudget(double value) async {
    monthlyBudget = value;
    await ReceiptRepository.saveReceipts(receipts, monthlyBudget);
    notifyListeners();
  }

  /// Clears any active [analysisError] flag.
  void clearError() {
    analysisError = null;
    notifyListeners();
  }
}
