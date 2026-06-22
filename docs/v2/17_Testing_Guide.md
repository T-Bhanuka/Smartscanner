# Testing Guide

This guide outlines setup instructions for writing and executing tests in the SmartScanner Pro codebase.

## 1. Running Tests
Run the following command to execute all tests in the workspace:
```bash
flutter test
```

## 2. Setting Up Unit Tests
Write unit tests for `Receipt` and `GalleryImage` JSON serialization inside `test/unit/`.

Example test structure:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:first_project/types.dart';

void main() {
  test('Receipt.fromJson maps valid data correctly', () {
    final json = {
      '_id': 'test-id',
      'storeName': 'Grocery Store',
      'total': 45.99,
      'date': '2026-06-10',
      'time': '',
      'category': 'Food',
      'timestamp': 1715858400000
    };
    final receipt = Receipt.fromJson(json);
    expect(receipt.id, 'test-id');
    expect(receipt.storeName, 'Grocery Store');
    expect(receipt.total, 45.99);
    expect(receipt.category, Category.Food);
  });
}
```

## 3. Mocking REST API Responses
Use `package:http/testing.dart` to mock network responses for testing:

```dart
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

final client = MockClient((request) async {
  return http.Response(jsonEncode({ 'token': 'mock-jwt-token' }), 200);
});
```
