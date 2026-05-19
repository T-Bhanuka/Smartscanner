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

class ReceiptItem {
  final String name;
  final double price;
  final Category category;

  ReceiptItem({
    required this.name,
    required this.price,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'price': price,
    'category': category.name,
  };

  factory ReceiptItem.fromJson(Map<String, dynamic> json) => ReceiptItem(
    name: json['name'],
    price: (json['price'] as num).toDouble(),
    category: Category.values.firstWhere(
      (e) => e.name == json['category'],
      orElse: () => Category.Other,
    ),
  );
}

class GalleryImage {
  final String id;
  final String base64;
  final int timestamp;
  final bool isProcessed;
  final String? linkedReceiptId;

  GalleryImage({
    required this.id,
    required this.base64,
    required this.timestamp,
    this.isProcessed = false,
    this.linkedReceiptId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'base64': base64,
    'timestamp': timestamp,
    'isProcessed': isProcessed,
    'linkedReceiptId': linkedReceiptId,
  };

  factory GalleryImage.fromJson(Map<String, dynamic> json) => GalleryImage(
    id: json['id'],
    base64: json['base64'],
    timestamp: json['timestamp'],
    isProcessed: json['isProcessed'] ?? false,
    linkedReceiptId: json['linkedReceiptId'],
  );
}