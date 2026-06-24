import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';

import '../types.dart';

/// A service responsible for extracting structured data from receipt images.
/// 
/// Uses Google ML Kit for on-device OCR (Text Recognition) and Entity Extraction
/// to parse store names, dates, and amounts. Currently limited to Latin script
/// and English entities.
class ReceiptProcessingService {
  /// Processes an image at [imagePath] and returns a parsed [Receipt] object.
  static Future<Receipt> processReceiptImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    late final String fullText;

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      fullText = recognizedText.text;
    } finally {
      await textRecognizer.close();
    }

    final entityExtractor = EntityExtractor(language: EntityExtractorLanguage.english);
    String shopName = _extractShopName(fullText);
    String date = DateTime.now().toIso8601String();
    double totalAmount = 0.0;

    try {
      final annotations = await entityExtractor.annotateText(fullText);

      for (final annotation in annotations) {
        for (final entity in annotation.entities) {
          if (entity.type == EntityType.money) {
            final moneyText = annotation.text.replaceAll(RegExp(r'[^0-9.]'), '');
            final val = double.tryParse(moneyText) ?? 0.0;
            if (val > totalAmount) {
              totalAmount = val;
            }
          } else if (entity.type == EntityType.dateTime) {
            date = annotation.text;
          }
        }
      }
    } finally {
      await entityExtractor.close();
    }

    return Receipt(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      storeName: shopName,
      date: date,
      time: '',
      items: const [],
      total: totalAmount,
      category: Category.Other,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      rawText: fullText,
    );
  }

  /// Heuristic to extract a likely shop name from raw OCR text.
  /// Currently picks the first non-empty line of text.
  static String _extractShopName(String fullText) {
    final lines = fullText
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    return lines.isNotEmpty ? lines.first.trim() : 'Unknown Shop';
  }
}
