import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

abstract class IFixedRecord<T> {
  final String columnName;

  T get value;
  
  IFixedRecord(this.columnName);
  
  void checkConsistency(IRecord<T> that) {
    assert( that.columnName == this.columnName, 'Cannot deep copy RecordBase with different column names.');
  }
}

/*! A minimalistic class that allows to store a value.
 * This is the base class of LazyRecord.
 * The LazyRecord adds the ability to track whether the value is available or not.
 */
abstract class IRecord<T> extends IFixedRecord<T> {

  set value (T newValue);
  T get value;
  
  bool hasChanged();
  
  IRecord(String columnName): super(columnName);
}

// Platform-agnostic data holder that can be tested on the VM.
class LazyRecord<T> extends IRecord<Future<T>> {

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
  
  LazyRecord.copy(LazyRecord<T> record)
      : value_completer = record.value_completer,
        _hasChanged = record._hasChanged,
        super(record.columnName) {
    checkConsistency(record);
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
class Record<T> extends IRecord<T> {

  T value;
  
  final T originalValue;
  bool hasChanged() {
    assert(value is String || value is int || value is double || value is bool, 'Expected value to be a primitive type (String, int, double, bool) since we compare it by value, got ${value.runtimeType}.');
    return value != originalValue;
  }

  Record(columnName, value): this.value = value, originalValue = value, super(columnName);
  
  Record.copy(Record<T> record):
    value = record.value,
    originalValue = record.originalValue,
    super(record.columnName)
    {
      checkConsistency(record);
      for (var v in [value, originalValue]) {
        assert(v is String || v is int || v is double || v is bool, 'Expected value to be a primitive type (String, int, double, bool) since we compare it by value, got ${v.runtimeType}.');
      }
    }
}

class FixedRecord<T> extends IFixedRecord<T> {
  final T value;
  
  FixedRecord(columnName, this.value): super(columnName);

  FixedRecord.copy(FixedRecord<T> record): value = record.value, super(record.columnName) {
    assert(value is String || value is int || value is double || value is bool, 'Expected value to be a primitive type (String, int, double, bool) since we compare it by value, got ${value.runtimeType}.');
  }
}

class ReferenceItem {
  // Minimal database fields we use (we keep the code maintainable this way).
  
  final FixedRecord<int> id; // `id` is an INT AUTO_INCREMENT PRIMARY KEY in the database.

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
  ReferenceItem.copy(ReferenceItem item) :
    id = FixedRecord<int>.copy(item.id),
    title = Record<String>.copy(item.title),
    authors = Record<String>.copy(item.authors),
    document = LazyRecord.copy(item.document);

  Future<Map<String, dynamic>> toJson() async {
  
    // Create json and conditionally add an optional property
    final map = <String, dynamic>{
      'id': id,
      'title': title.value,
      'authors': authors.value,
    };

    if (document.hasChanged()) {
      final Future<ByteData?> futureData = document.value;
      assert(futureData is! Completer<ByteData?>, 'Expected the document future to be completed by now.');
      final ByteData? data = await futureData;

      map['documentBlob'] =
          (data == null) ? null : base64Encode(data.buffer.asUint8List());
    }
    return map;
  }

  bool hasChanged() {

    // If any field has changed, the item has changed.
    return <IRecord<dynamic>>[
      title,
      authors,
      document
    ]
        .any((f) => f.hasChanged());
  }
}
