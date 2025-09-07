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
  String title;
  String authors;
  LazyByteData document;

  ReferenceItem({this.title = '', this.authors = '', LazyByteData? documentBlob})
      : document = documentBlob ?? LazyByteData();

  ReferenceItem clone() => ReferenceItem(title: title, authors: authors);

  void copyPropertiesFrom(ReferenceItem other) {
    title = other.title;
    authors = other.authors;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
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

  bool matches(ReferenceItem that) => title == that.title && authors == that.authors;
}
