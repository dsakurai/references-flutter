import 'dart:convert';
import 'dart:typed_data';

// Platform-agnostic data holder that can be tested on the VM.
class LazyByteData {
  ByteData? _lazyData;
  bool _isLazyDataAvailable = false;

  bool get isLazyDataAvailable => _isLazyDataAvailable;

  set lazyData(ByteData? data) {
    _lazyData = data;
    _isLazyDataAvailable = true;
  }

  ByteData? get lazyData {
    if (!_isLazyDataAvailable) {
      throw StateError('Value not downloaded.');
    }
    return _lazyData;
  }

  void clearData() {
    _isLazyDataAvailable = false;
    _lazyData = null;
  }

  LazyByteData();

  LazyByteData.withData(ByteData? data, bool available) {
    // Setter marks available = true
    lazyData = data;
    assert(available == true,
        'LazyByteData: you have to assign the value if you provide an initial value.');
  }

  LazyByteData.fromJson(String? json, bool available)
      : this.withData(
            (json == null) ? null : ByteData.view(base64Decode(json).buffer),
            available);
}

class ReferenceItem {
  // Minimal fields we actively use (keep maintainable)
  int? id; // `id` INT AUTO_INCREMENT PRIMARY KEY
  String title; // `title`
  String authors; // `authors`
  LazyByteData document; // `document` (longblob)

  ReferenceItem({
    this.id,
    this.title = '',
    this.authors = '',
    LazyByteData? documentBlob,
  }) : document = documentBlob ?? LazyByteData();

  ReferenceItem clone() => ReferenceItem(
        id: id,
        title: title,
        authors: authors,
        documentBlob: document,
      );

  void copyPropertiesFrom(ReferenceItem other) {
    id = other.id;
    title = other.title;
    authors = other.authors;
    document = other.document;
  }

  Map<String, dynamic> toJson() {
  
    // Create json and conditionally add an optional property
    final map = <String, dynamic>{
      'id': id,
      'title': title,
      'authors': authors,
    };

    if (document.isLazyDataAvailable) {
      final data = document._lazyData;
      map['documentBlob'] =
          (data == null) ? null : base64Encode(data.buffer.asUint8List());
    }
    return map;
  }

  // TODO make available the document data before comparing?
  bool matches(ReferenceItem that) => title == that.title && authors == that.authors && authors == that.authors && document == that.document;
}
