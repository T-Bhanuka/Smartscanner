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
    'galleryImageId': galleryImageId,
  };

  factory Receipt.fromJson(Map<String, dynamic> json) {
    Category parsedCategory = Category.Other;
    try {
      parsedCategory = Category.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['category'] ?? '').toString().toLowerCase(),
        orElse: () => Category.Other,
      );
    } catch (_) {}

    int parsedTimestamp = 0;
    final tsValue = json['timestamp'] ?? json['createdAt'];
    if (tsValue is int) {
      parsedTimestamp = tsValue;
    } else if (tsValue is String) {
      final parsed = DateTime.tryParse(tsValue);
      if (parsed != null) {
        parsedTimestamp = parsed.millisecondsSinceEpoch;
      }
    } else {
      final parsed = DateTime.tryParse(json['date'] ?? '');
      if (parsed != null) {
        parsedTimestamp = parsed.millisecondsSinceEpoch;
      }
    }

    return Receipt(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      storeName: (json['storeName'] ?? 'Unknown Store').toString(),
      date: (json['date'] ?? '').toString(),
      time: (json['time'] ?? '').toString(),
      items: json['items'] is List
          ? (json['items'] as List).map((e) => ReceiptItem.fromJson(e)).toList()
          : [],
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      category: parsedCategory,
      timestamp: parsedTimestamp,
      galleryImageId: json['galleryImageId']?.toString(),
    );
  }
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

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    Category parsedCategory = Category.Other;
    try {
      parsedCategory = Category.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['category'] ?? '').toString().toLowerCase(),
        orElse: () => Category.Other,
      );
    } catch (_) {}

    return ReceiptItem(
      name: (json['name'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: parsedCategory,
    );
  }
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

  factory GalleryImage.fromJson(Map<String, dynamic> json) {
    int parsedTimestamp = 0;
    final tsValue = json['timestamp'] ?? json['createdAt'];
    if (tsValue is int) {
      parsedTimestamp = tsValue;
    } else if (tsValue is String) {
      final parsed = DateTime.tryParse(tsValue);
      if (parsed != null) {
        parsedTimestamp = parsed.millisecondsSinceEpoch;
      }
    }
    return GalleryImage(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      base64: (json['base64'] ?? json['imageUrl'] ?? '').toString(),
      timestamp: parsedTimestamp,
      isProcessed: json['isProcessed'] == true || json['isProcessed']?.toString() == 'true',
      linkedReceiptId: (json['linkedReceiptId'] ?? json['receipt'])?.toString(),
    );
  }
}
