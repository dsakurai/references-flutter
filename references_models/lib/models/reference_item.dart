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

  T value;
  
  final String columnName;

  Record(this.columnName,
         this.value,
        );

  // TODO Seems I don't need this method. However, later I might want to deep copy LazyByteData.
  void deepCopy(Record<T> that) {
    this.value      = that.value;
    assert( that.columnName == this.columnName, 'Cannot deep copy Record with different column names.');
  }
}

class ReferenceItem {
  // Minimal database fields we use (we keep the code maintainable this way).
  
  // TODO make final and use LazyRecord<int?> id
  int? id = null; // `id` INT AUTO_INCREMENT PRIMARY KEY

  final   title = Record<String>('title',  ''); // `title`
  final authors = Record<String>('authors',''); // `authors`
  LazyByteData document; // `document` (longblob)
  
  
  ReferenceItem({
    id = null,
    title = '',
    authors = '',
    LazyByteData? documentBlob,
  })  : id = id,
        document = documentBlob ?? LazyByteData()
        {
    this.title.value = title;
    this.authors.value = authors;
  }

  // Only used internally for deep copying
  ReferenceItem._fromRecords(
    int? id,
    Record<String> title,
    Record<String> authors,
    documentBlob,
  ) : id       = id,
      document = documentBlob ?? LazyByteData()
  {
    this.title.deepCopy(title);
    this.authors.deepCopy(authors);
  }
        
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
