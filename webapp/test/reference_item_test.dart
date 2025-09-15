import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:references_models/models/reference_item.dart';

void main() {
  group('ReferenceItem.toJson dynamic omission', () {
    test('omits documentBlob when not available', () {
      final item = ReferenceItem(title: 'A', authors: 'B');

      final json = item.toJson();

      expect(json['title'], 'A');
      expect(json['authors'], 'B');
      expect(json.containsKey('documentBlob'), isFalse);
    });

    test('includes documentBlob: null when available but null', () {
      final item = ReferenceItem(title: 'A', authors: 'B');
      // Mark as available but null
      item.document.value = null;

      final json = item.toJson();

      expect(json.containsKey('documentBlob'), isTrue);
      expect(json['documentBlob'], isNull);
    });

    test('includes base64 when available with data', () {
      final item = ReferenceItem(title: 'A', authors: 'B');
      final data = ByteData.view(Uint8List.fromList([1, 2, 3]).buffer);
      item.document.value = data;

      final json = item.toJson();

      expect(json.containsKey('documentBlob'), isTrue);
      expect(json['documentBlob'], base64Encode([1, 2, 3])); // 'AQID'
    });
  });
}
