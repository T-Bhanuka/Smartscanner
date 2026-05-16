import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/receipt_processing_service.dart';
import '../services/receipt_repository.dart';
import '../types.dart';

class AppState extends ChangeNotifier {
  List<Receipt> receipts = [];
  List<GalleryImage> galleryImages = [];
  bool isAnalyzing = false;
  String? analysisError;
  double monthlyBudget = 20000;

  Future<void> loadData() async {
    receipts = await ReceiptRepository.loadReceipts();
    galleryImages = await ReceiptRepository.loadGalleryImages();
    monthlyBudget = await ReceiptRepository.loadMonthlyBudget();
    galleryImages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

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
    }
  }

  Future<void> deleteGalleryItem(String id) async {
    galleryImages.removeWhere((img) => img.id == id);
    await ReceiptRepository.deleteGalleryImage(id);
    notifyListeners();
  }

  Future<void> deleteReceipt(String id) async {
    receipts.removeWhere((r) => r.id == id);
    await ReceiptRepository.saveReceipts(receipts, monthlyBudget);
    notifyListeners();
  }

  Future<void> updateBudget(double value) async {
    monthlyBudget = value;
    await ReceiptRepository.saveReceipts(receipts, monthlyBudget);
    notifyListeners();
  }

  void clearError() {
    analysisError = null;
    notifyListeners();
  }
}
