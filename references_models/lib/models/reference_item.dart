import 'dart:convert';
import 'dart:typed_data';

/*! A minimalistic class that allows to store a value.
 * This is the base class of LazyRecord.
 * The LazyRecord adds the ability to track whether the value is available or not.
 */
abstract class RecordBase<T> {

  final String columnName;

  set value (T newValue);
  T get value;
  
  bool hasChanged();
  
  RecordBase(this.columnName);
  
  void _deepCopy(RecordBase<T> that) {
    this.value      = that.value;
    assert( that.columnName == this.columnName, 'Cannot deep copy RecordBase with different column names.');
  }
}

// Platform-agnostic data holder that can be tested on the VM.
class LazyRecord<T> extends RecordBase<T> {
  late T _lazyValue;
  bool _isLazyValueAvailable = false;

  bool get isLazyValueAvailable => _isLazyValueAvailable;
  
  bool _hasChanged = false;

  set value(T newValue) {
    _lazyValue = newValue;
    _isLazyValueAvailable = true;

    _hasChanged = true;
  }

  T get value {
    if (!_isLazyValueAvailable) {
      throw StateError('Value not downloaded.');
    }
    return _lazyValue;
  }
  
  bool hasChanged() {
    return _hasChanged;
  }

  LazyRecord(columnName) : _isLazyValueAvailable = false, super(columnName) {
  }

  // TODO Seems I don't need this method.
  void deepCopy(LazyRecord<T> that) {
    _isLazyValueAvailable = that._isLazyValueAvailable;
    _hasChanged = that._hasChanged;

    if (that._isLazyValueAvailable) {
      // yes => copy it
      _deepCopy(that);
    }
  }

  // void unloadValue() {
  //   _isLazyValueAvailable = false;
  //   updateTimeStamp();
  // }
  
  // LazyRecord.withData(T newValue, bool available) {
  //   // Setter marks available = true
  //   value = newValue;
  //   assert(available == true,
  //       'LazyByteData: you have to assign the value if you provide an initial value.');
  // }

  // LazyRecord.fromJson(String? json, bool available)
  //     : this.withData(
  //           (json == null) ? null : ByteData.view(base64Decode(json).buffer),
  //           available);
}

/**
 * A record / cell in the database table.
 * Tracks whether it has been modified by the enduser.
 */
class Record<T> extends RecordBase<T> {

  T value;
  
  /*final*/ T originalValue;
  bool hasChanged() {
    assert(value is String || value is int || value is double || value is bool, 'Expected value to be a primitive type (String, int, double, bool) since we compare it by value, got ${value.runtimeType}.');
    
    print(originalValue);
    print(value);

    return value != originalValue;
  }

  Record(columnName, value): this.value = value, originalValue = value, super(columnName);

  void deepCopy(Record<T> that) {
    _deepCopy(that);
    this.originalValue = that.originalValue;
    print(that.originalValue);
    print(this.originalValue);
  }
}

class ReferenceItem {
  // Minimal database fields we use (we keep the code maintainable this way).
  
  // TODO make final and use LazyRecord<int?> id
  int? id = null; // `id` INT AUTO_INCREMENT PRIMARY KEY

  var title    = Record<String>('title',  ''); // `title`
  var authors  = Record<String>('authors',''); // `authors`
  var document = LazyRecord<ByteData?>('document'); // `document` (longblob)
  
  
  ReferenceItem({
    id = null,
    title = '',
    authors = '',
  })  : id = id,
        title = Record<String>('title',  title),
        authors = Record<String>('authors',authors),
        document = LazyRecord<ByteData?>('document');

  // Only used internally for deep copying
  ReferenceItem._fromRecords(
    int? id,
    Record<String> title,
    Record<String> authors,
    LazyRecord<ByteData?> document,
  ) : id       = id
  {
    this.title.deepCopy(title);
    this.authors.deepCopy(authors);
    this.document.deepCopy(document);
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

    if (document.isLazyValueAvailable) {
      final data = document._lazyValue;
      map['documentBlob'] =
          (data == null) ? null : base64Encode(data.buffer.asUint8List());
    }
    return map;
  }

  // TODO make available the document data before comparing?
  bool hasChanged() {

    // If any field has changed, the item has changed.
    return <RecordBase<dynamic>>[
      title,
      authors,
      /*document*/
    ]
        .any((f) => f.hasChanged());
  }
}
