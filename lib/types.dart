/// Represents the high-level category of an expense or receipt.
// ignore_for_file: constant_identifier_names
enum Category {
  Food,
  Furniture,
  Stationery,
  Medicine,
  BabyAccessories,
  MobileAccessories,
  PetItems,
  BankPayment,
  Transport,
  Other,
}

/// A core domain model representing a single captured or imported receipt.
/// 
/// Contains both structured data (like [total] and [date]) and raw data
/// (like [rawText] from OCR). Receipts are persisted locally and optionally
/// synchronized to Firestore (indicated by [firestoreId]).
class Receipt {
  final String id;
  final String storeName;
  final String date;
  final String time;
  final List<ReceiptItem> items;
  final double total;
  final Category category;
  final int timestamp;
  String? firestoreId;
  final String? rawText;
  final String? galleryImageId;

  /// Creates a new [Receipt] instance.
  Receipt({
    required this.id,
    required this.storeName,
    required this.date,
    required this.time,
    required this.items,
    required this.total,
    required this.category,
    required this.timestamp,
    this.firestoreId,
    this.rawText,
    this.galleryImageId,
  });

  /// Serializes the receipt to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'storeName': storeName,
    'date': date,
    'time': time,
    'items': items.map((e) => e.toJson()).toList(),
    'total': total,
    'category': category.name,
    'timestamp': timestamp,
    'rawText': rawText,
    'galleryImageId': galleryImageId,
    'firestoreId': firestoreId,
  };

  /// Deserializes a [Receipt] from a JSON map.
  factory Receipt.fromJson(Map<String, dynamic> json) => Receipt(
    id: json['id'],
    storeName: json['storeName'],
    date: json['date'],
    time: json['time'],
    items: (json['items'] as List).map((e) => ReceiptItem.fromJson(e)).toList(),
    total: (json['total'] as num).toDouble(),
    category: Category.values.firstWhere(
      (e) => e.name == json['category'],
      orElse: () => Category.Other,
    ),
    timestamp: json['timestamp'],
    rawText: json['rawText'] as String?,
    galleryImageId: json['galleryImageId'],
    firestoreId: json['firestoreId'] as String?,
  );
}

/// A domain model representing a single purchased item on a receipt.
/// 
/// Note: Item-level extraction is not fully implemented in the current OCR pipeline.
class ReceiptItem {
  final String name;
  final double price;
  final Category category;

  /// Creates a new [ReceiptItem].
  ReceiptItem({
    required this.name,
    required this.price,
    required this.category,
  });

  /// Serializes the receipt item to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'name': name,
    'price': price,
    'category': category.name,
  };

  /// Deserializes a [ReceiptItem] from a JSON map.
  factory ReceiptItem.fromJson(Map<String, dynamic> json) => ReceiptItem(
    name: json['name'],
    price: (json['price'] as num).toDouble(),
    category: Category.values.firstWhere(
      (e) => e.name == json['category'],
      orElse: () => Category.Other,
    ),
  );
}

/// Represents an image imported from the gallery or captured by the camera,
/// stored locally as a base64 string for the Vault tab.
class GalleryImage {
  final String id;
  final String base64;
  final int timestamp;
  bool isProcessed;
  final String? linkedReceiptId;

  /// Creates a new [GalleryImage].
  GalleryImage({
    required this.id,
    required this.base64,
    required this.timestamp,
    this.isProcessed = false,
    this.linkedReceiptId,
  });

  /// Serializes the gallery image record to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'base64': base64,
    'timestamp': timestamp,
    'isProcessed': isProcessed,
    'linkedReceiptId': linkedReceiptId,
  };

  /// Deserializes a [GalleryImage] from a JSON map.
  factory GalleryImage.fromJson(Map<String, dynamic> json) => GalleryImage(
    id: json['id'],
    base64: json['base64'],
    timestamp: json['timestamp'],
    isProcessed: json['isProcessed'] ?? false,
    linkedReceiptId: json['linkedReceiptId'],
  );
}