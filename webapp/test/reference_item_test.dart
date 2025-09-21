import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:references_models/models/reference_item.dart';

void main() {
  group('ReferenceItem.toJson dynamic omission', () {
    test('omits documentBlob when not available', () async {
      final item = ReferenceItem(0, title: 'A', authors: 'B');

      final json = await item.toJson();

      expect(json['title'], 'A');
      expect(json['authors'], 'B');
      expect(json.containsKey('documentBlob'), isFalse);
    });

    test('includes documentBlob: null when available but null', () async {
      final item = ReferenceItem(1, title: 'A', authors: 'B');
      // Mark as available but null
      item.document.value = Future<ByteData?>.value(null);

      final json = await item.toJson();

      expect(json.containsKey('documentBlob'), isTrue);
      expect(json['documentBlob'], isNull);
    });

    test('includes base64 when available with data', () async {
      final item = ReferenceItem(2, title: 'A', authors: 'B');
      final data = ByteData.view(Uint8List.fromList([1, 2, 3]).buffer);
      item.document.value = Future<ByteData?>.value(data);

      final json = await item.toJson();

      expect(json.containsKey('documentBlob'), isTrue);
      expect(json['documentBlob'], base64Encode([1, 2, 3])); // 'AQID'
    });
  });
}
