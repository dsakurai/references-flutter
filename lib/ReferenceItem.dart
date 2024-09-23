import 'dart:typed_data';

import 'package:flutter/material.dart';

@immutable
class LocalBinary {
  // null indicates that the blob is null in the database
  final ByteBuffer? _byteBuffer;

  // Do not change the properties of byteBuffer!
  ByteBuffer? get byteBuffer {
    return _byteBuffer;
  }

  bool isNullInDatabase() {
    return _byteBuffer == null;
  }

  LocalBinary({required ByteBuffer? byteBuffer}) : _byteBuffer = byteBuffer;

  LocalBinary.nullValue() : this(byteBuffer: null);
}

typedef FunctionLoadBinary = Future<LocalBinary> Function();

class DocumentPointer {
  // null indicates that data is not downloaded from the database because there has been no request from the user.
  // The local binary of a PDF (or powerpoint etc.) can be updated, in which case this LocalBinary instance is replaced with a newly constructed one.
  Future<LocalBinary>?
      _local; // Note: if the actual blob is null in the database but is already locally stored (as a null value), `_local` is non-null.

  FunctionLoadBinary? _lazyLoad;

  bool _userChangedBinary = false;
  bool userMadeAChange() {
    return _userChangedBinary;
  }

  void setUserSpecifiedBinary(LocalBinary binary) {
    _userChangedBinary = true;
    _local = Future<LocalBinary>.value(binary);
  }

  Future<LocalBinary> get local async {

    if (_local case var loc?) {
      return loc;
    } else {

      // Load the binary
      if (this._lazyLoad case var load?) {
        Future<LocalBinary> binary = load();
        _local = binary;
        return binary;

      } else { throw Exception("No downloader set!"); }
    }

  }

  // Document binary is stored locally. Might also be stored in the database.
  bool get storedLocally {
    return _local != null;
  }

  DocumentPointer._({
    required Future<LocalBinary>? local,
    required FunctionLoadBinary?  lazyLoad,
    }) :
     _local      = local,
     _lazyLoad = lazyLoad
    ;

  // Constructor
  DocumentPointer.lazyLoad({
    required FunctionLoadBinary func
  }): this._(
    local: null,
    lazyLoad: func
  );

  // Set the document to null in the database.
  // Useful for a new item that is not in the database yet.
  DocumentPointer.nullInDataBase()
      : this._(
        local: Future<LocalBinary>.value(LocalBinary.nullValue()),
        lazyLoad: null
        );

  // Used for generating a temporary reference item that can be edited by the user.
  // The copied item can be removed if the user does not edit the record.
  // Not meant to be used by the user of this file, at least for now.
  DocumentPointer _clone() =>
      DocumentPointer._(
        local: this._local, // point at the same local binary.
        lazyLoad: this._lazyLoad
      )
  ;
}

class ReferenceItem {
  String title;
  String authors;
  DocumentPointer
      documentPointer; // the actual binary might not be fetched from the database

  ReferenceItem clone() {
    ReferenceItem c = ReferenceItem();
    c.copyPropertiesFrom(this);
    return c;
  }

  void copyPropertiesFrom(ReferenceItem other) {
    title = other.title;
    authors = other.authors;
    documentPointer = other.documentPointer
        ._clone(); // although a clone, the binary points at the same blob instance (stored locally or in the database).
  }

  ReferenceItem({
    this.title = "",
    this.authors = "",
  }) : documentPointer = DocumentPointer.nullInDataBase();

  ReferenceItem.withLazyLoad({
    this.title = "",
    this.authors = "",
    required FunctionLoadBinary lazyLoad,
  }) : documentPointer = DocumentPointer.lazyLoad(func: lazyLoad)
  ;

  bool userMadeAChange(ReferenceItem original) {

    // Rule of thumb: compare by values
    return
        // Strings can be compared by their values in this manner
        (title != original.title) ||
            (authors != original.authors) ||
            documentPointer.userMadeAChange();
  }
}
