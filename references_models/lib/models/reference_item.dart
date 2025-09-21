import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

abstract class FixedRecordBase<T> {
  final String columnName;

  T get value;
  
  FixedRecordBase(this.columnName);
  
  void _deepCopy(RecordBase<T> that) {
    assert( that.columnName == this.columnName, 'Cannot deep copy RecordBase with different column names.');
  }
}

/*! A minimalistic class that allows to store a value.
 * This is the base class of LazyRecord.
 * The LazyRecord adds the ability to track whether the value is available or not.
 */
abstract class RecordBase<T> extends FixedRecordBase<T> {

  set value (T newValue);
  T get value;
  
  bool hasChanged();
  
  RecordBase(String columnName): super(columnName);
}

// Platform-agnostic data holder that can be tested on the VM.
class LazyRecord<T> extends RecordBase<Future<T>> {

  Completer<T> value_completer = Completer<T>(); // Provides the value once available

  bool _hasChanged = false;

  @override
  set value(Future<T> newValue) {
    final c = value_completer = Completer<T>(); // reset on each assignment
    newValue.then(c.complete, onError: c.completeError);

    _hasChanged = true;
  }
  
  // // Optional: accept both T and Future<T>
  // void setValue(FutureOr<T> v) {
  //   final c = _completer = Completer<T>();
  //   Future.sync(() => v).then(c.complete, onError: c.completeError);
  //   _hasChanged = true;
  // }


  @override
  Future<T> get value {
    return value_completer.future;
  }
  
  bool hasChanged() {
    return _hasChanged;
  }

  LazyRecord(columnName, this.value_completer): super(columnName);
  LazyRecord.withValue(columnName, T value)
    : this.value_completer = Completer<T>()..complete(value),
  super(columnName);

  void deepCopy(LazyRecord<T> that) {
    value_completer = that.value_completer;
    _hasChanged = that._hasChanged;

    _deepCopy(that);
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
  
  /*final*/ T originalValue;
  bool hasChanged() {
    assert(value is String || value is int || value is double || value is bool, 'Expected value to be a primitive type (String, int, double, bool) since we compare it by value, got ${value.runtimeType}.');

    return value != originalValue;
  }

  Record(columnName, value): this.value = value, originalValue = value, super(columnName);

  void deepCopy(Record<T> that) {
    _deepCopy(that);
    this.originalValue = that.originalValue;
    this.value      = that.value;
  }
}

class FixedRecord<T> extends FixedRecordBase<T> {
  final T value;
  
  FixedRecord(columnName, this.value): super(columnName);

  FixedRecord.copy(FixedRecord<T> record): value = record.value, super(record.columnName);
}

class ReferenceItem {
  // Minimal database fields we use (we keep the code maintainable this way).
  
  final FixedRecord<int> id; // `id` INT AUTO_INCREMENT PRIMARY KEY

  final Record<String> title; // `title`
  final Record<String> authors; // `authors`
  final LazyRecord<ByteData?> document; // `document` (longblob)
  
  
  ReferenceItem(
    int id,
    {
    title = '',
    authors = '',
    Completer<ByteData?>? documentCompleter = null,
  })  : id    = FixedRecord<int>('id', id),
        title = Record<String>('title',  title),
        authors = Record<String>('authors',authors),
        document = LazyRecord('document', documentCompleter ?? Completer<ByteData?>());

  // Only used internally for deep copying
  ReferenceItem._fromRecords(
    FixedRecord<int>    id,
    Record<String> title,
    Record<String> authors,
    LazyRecord<ByteData?> document,
  ) : id       = FixedRecord<int>.copy(id),
      // TODO fix this to use `copy` constructors
      title    = Record<String>(title.columnName,   ''),
      authors  = Record<String>(authors.columnName, ''),
      document = LazyRecord(document.columnName, Completer<ByteData?>())
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

    if (document.hasChanged()) {
      final Future<ByteData?> futureData = document.value;
      assert(futureData is! Completer<ByteData?>, 'Expected the document future to be completed by now.');
      final ByteData? data = futureData as ByteData?;

      map['documentBlob'] =
          (data == null) ? null : base64Encode(data.buffer.asUint8List());
    }
    return map;
  }

  bool hasChanged() {

    // If any field has changed, the item has changed.
    return <RecordBase<dynamic>>[
      title,
      authors,
      document
    ]
        .any((f) => f.hasChanged());
  }
}
