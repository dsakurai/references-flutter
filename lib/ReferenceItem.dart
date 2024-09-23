import 'dart:typed_data';

import 'package:flutter/material.dart';

@immutable
class LocalBinary {

  // null indicates that the blob is null in the database
  final ByteBuffer? _byteBuffer;

  bool isNullInDatabase () {
    return _byteBuffer == null;
  }

  LocalBinary({
    required ByteBuffer? byteBuffer
  }): _byteBuffer = byteBuffer;

  LocalBinary.nullValue(): this(byteBuffer: null);
}

class DocumentPointer {

  // null indicates that data is not downloaded from the database because there has been no request from the user.
  // The local binary of a PDF (or powerpoint etc.) can be updated, in which case this LocalBinary instance is replaced with a newly constructed one.
  Future<LocalBinary>? _local; // Note: if the actual blob is null in the database but is already locally stored (as a null value), `_local` is non-null.

  bool _userChangedBinary = false;
  bool userMadeAChange() { return _userChangedBinary; }

  void setUserSpecifiedBinary(LocalBinary binary) {
    _userChangedBinary = true;
    _local = Future<LocalBinary>.value(binary);
  }

  Future<LocalBinary> get local async {

    // Return if non null
    if (_local case var loc?) { return loc; }

    throw UnimplementedError("Downloading from the database is not implemented yet.");

    // _local = await download();
    // return _local;
  }

  // Document binary is stored locally. Might also be stored in the database.
  bool get storedLocally { return _local != null; }

  DocumentPointer._({
    required Future<LocalBinary>? local
  }): _local = local
  ;

  // TODO remove this.
  // 
  // Not for production.
  // A quick hack for creating a sample version. 
  //
  // To be replaced with a database mock.
  DocumentPointer.testData({
    required Future<LocalBinary>? local
  }): this._(local: local);

  // Set the document to null in the database.
  // Useful for a new item that is not in the database yet.
  DocumentPointer.nullInDataBase(): this._(
      local: Future<LocalBinary>.value(LocalBinary.nullValue())
  );


  // Used for generating a temporary reference item that can be edited by the user.
  // The copied item can be removed if the user does not edit the record.
  DocumentPointer clone() => DocumentPointer._(
    local: this._local // point at the same local binary.
  );
}

class ReferenceItem {
  String title;
  String authors;
  DocumentPointer documentPointer; // the actual binary might not be fetched from the database

  ReferenceItem clone() {
    ReferenceItem c = ReferenceItem();
    c.copyPropertiesFrom(this);
    return c;
  }

  void copyPropertiesFrom(ReferenceItem other) {
    title = other.title;
    authors = other.authors;
    documentPointer = other.documentPointer.clone();  // although a clone, the binary points at the same blob instance (stored locally or in the database).
  }

  ReferenceItem({this.title = "",
                 this.authors = "",
                 DocumentPointer? documentPointer = null // If un-specified, we will create a database entry whose document blob is A null (not only locally, but also in the database).
  }):
    this.documentPointer = documentPointer?? DocumentPointer.nullInDataBase();

  bool userMadeAChange(ReferenceItem original) {

    // Rule of thumb: compare by values
    return
        // Strings can be compared by their values in this manner
           (title != original.title)
        || (authors != original.authors)
        || documentPointer.userMadeAChange();
  }
}
