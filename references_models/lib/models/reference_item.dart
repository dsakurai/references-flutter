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

  set value(T newValue) {
    _lazyValue = newValue;
    _isLazyValueAvailable = true;
  }

  T get value {
    if (!_isLazyValueAvailable) {
      throw StateError('Value not downloaded.');
    }
    return _lazyValue;
  }

  void unloadValue() {
    _isLazyValueAvailable = false;
  }
  
  LazyRecord(columnName) : _isLazyValueAvailable = false, super(columnName);
  
  void deepCopy(LazyRecord<T> that) {
    this._isLazyValueAvailable = that._isLazyValueAvailable;

    // is the final value already set?
    if (that._isLazyValueAvailable) {
      // yes => copy it
      _deepCopy(that);
    }
  }
  
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

  Record(columnName, this.value): super(columnName);

  // TODO Seems I don't need this method. However, later I might want to deep copy LazyByteData.
  void deepCopy(Record<T> that) {
    _deepCopy(that);
  }
}

class ReferenceItem {
  // Minimal database fields we use (we keep the code maintainable this way).
  
  // TODO make final and use LazyRecord<int?> id
  int? id = null; // `id` INT AUTO_INCREMENT PRIMARY KEY

  final   title  = Record<String>('title',  ''); // `title`
  final authors  = Record<String>('authors',''); // `authors`
  final document = LazyRecord<ByteData?>('document'); // `document` (longblob)
  
  
  ReferenceItem({
    id = null,
    title = '',
    authors = '',
  })  : id = id
        {
    this.title.value = title;
    this.authors.value = authors;
  }

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
  bool isModified(ReferenceItem that) {
    assert(this.id == that.id);

    assert(title.value is String, 'Expected title.value to be a String since we compare it by value, got ${title.value.runtimeType}.');
    if (title.value != that.title.value ) {
      return false;
    }

    assert(authors.value is String, 'Expected title.value to be a String since we compare it by value, got ${title.value.runtimeType}.');
    if (authors.value != that.authors.value) {
      return false;
    }

    // TODO FIX THIS
    // if (!document.isLazyValueAvailable) {
    //   return false;
    // }  
    
    return true;
  }
}
