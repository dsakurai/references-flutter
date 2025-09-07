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

/**
 * A record / cell in the database table.
 * Tracks whether it has been modified by the enduser.
 */
class Record<T> {

  // Keeps track of modifications
  bool _isModified = false;
  get isModified => _isModified;

  T _value;
  T get value => _value;
  
  // Mark as modified on set
  set value(T newValue) {
    _isModified = true;
    _value = newValue;
  }

  final String columnName;

  Record(this.columnName,
         value,
        {isModified = false} // can be optionally set to allow a deep copy of this class instance
        ):
    _value    = value,       // Initial the value, but do not mark as modified because the user did not change it
    _isModified = isModified;

  Record<T> deepCopy() => Record<T>(columnName, _value, isModified: _isModified);
}

class ReferenceItem {
  // Minimal fields we actively use (keep maintainable)
  
  // TODO make final and use LazyRecord<int?> id
  int? id = null; // `id` INT AUTO_INCREMENT PRIMARY KEY

  // TODO I probably don't need to hold these as Record class instances. Instead, generate Record instances dynamically with a getter.
  final Record<String> title; // `title`
  final Record<String> authors; // `authors`
  LazyByteData document; // `document` (longblob)
  
  
  ReferenceItem({
    id = null,
    title = '',
    authors = '',
    LazyByteData? documentBlob,
  })  : id = id,
        title = Record<String>('title', title),
        authors = Record<String>('authors', authors),
        document = documentBlob ?? LazyByteData();

  // Only used internally for deep copying
  ReferenceItem._fromRecords(
    int? id,
    Record<String> title,
    Record<String> authors,
    documentBlob,
  ) : id        = id,
       title    = title.deepCopy(),
       authors  = authors.deepCopy(),
       document = documentBlob ?? LazyByteData();
        
  ReferenceItem deepCopy() => ReferenceItem._fromRecords(
        id,
        title,
        authors,
        document,
      );

  Map<String, dynamic> toJson() {
  
    // Create json and conditionally add an optional property
    final map = <String, dynamic>{
      'id': id,
      'title': title.value,
      'authors': authors.value,
    };

    if (document.isLazyDataAvailable) {
      final data = document._lazyData;
      map['documentBlob'] =
          (data == null) ? null : base64Encode(data.buffer.asUint8List());
    }
    return map;
  }

  // TODO make available the document data before comparing?
  bool isModified(ReferenceItem that) => title.value == that.title.value && authors.value == that.authors.value && document == that.document;
}
