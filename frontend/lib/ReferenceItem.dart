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

  void sanityCheck() {
      // If the document is stored remotely, the lazy loading function must be available.
      if (_local == null && _lazyLoad == null) throw Exception("Warning: local and lazyLoad are both null.");

      // Below should not go into sanity check because after a download happens (i.e. local data is non-null), lazyLoading function can still be non-null.
      // if (_local != null && _lazyLoad != null) { throw Exception("Error: local and lazyLoad are both set."); }
  }

  bool _userChangedBinary = false;
  bool userMadeAChange() {
    return _userChangedBinary;
  }

  void setUserSpecifiedBinary(LocalBinary binary) {
    sanityCheck(); // This is technically not a problem, but is not intended. Might capture a future bug.

    _userChangedBinary = true;

    _lazyLoad = null;
    _local = Future<LocalBinary>.value(binary);
  }

  Future<LocalBinary> get local async { sanityCheck();
    // Document is locally available? 
    if (_local case var loc?) {
      return loc; // yes => return

    } else { // => download document

      // lazy-loading function for downloading is set?
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

  // Only meant for delegation
  DocumentPointer._delegationOnly({
    required Future<LocalBinary>? local,
    required FunctionLoadBinary?  lazyLoad,
    }) :
     _local    = local,
     _lazyLoad = lazyLoad
    {
      sanityCheck();
    }

  // Constructor
  DocumentPointer._withLazyLoad({
    required FunctionLoadBinary func
  }): this._delegationOnly(
    local: null,
    lazyLoad: func
  );

  // Set the document to null in the database.
  // Useful for a new item that is not in the database yet.
  DocumentPointer._nullInDataBase()
      : this._delegationOnly(
        local: Future<LocalBinary>.value(LocalBinary.nullValue()),
        lazyLoad: null
        );

  // Used for generating a temporary reference item that can be edited by the user.
  // The copied item can be removed if the user does not edit the record.
  // Not meant to be used by the user of this file, at least for now.
  DocumentPointer _clone() =>
      DocumentPointer._delegationOnly(
        local: this._local, // point at the same local binary.
        lazyLoad: this._lazyLoad
      )
  ;
}

class ReferenceItem {
  int? id; // Note: items in the database SHOULD have an ID.
  String title;
  String authors;
  DocumentPointer _documentPointer; // the actual binary might not be fetched from the database

  DocumentPointer get documentPointer {
    return _documentPointer;
  }

  ReferenceItem clone() {
    ReferenceItem c = ReferenceItem.emptyItem();
    c.copyPropertiesFrom(this);
    return c;
  }

  void copyPropertiesFrom(ReferenceItem other) {
    title = other.title;
    authors = other.authors;
    _documentPointer = other.documentPointer
        ._clone(); // although a clone, the binary points at the same blob instance (stored locally or in the database).
  }

  ReferenceItem.emptyItem({
    this.id = null,
    this.title = "",
    this.authors = "",
  }) : _documentPointer = DocumentPointer._nullInDataBase();

  ReferenceItem.withLazyLoad({
    this.id = null,
    this.title = "",
    this.authors = "",
    required FunctionLoadBinary lazyLoad,
  }) : _documentPointer = DocumentPointer._withLazyLoad(func: lazyLoad)
  ;

  bool userMadeAChange(ReferenceItem original) {

    if (this.id != original.id) {
      throw Exception("ID differs! User made a change on the ID?");
    } // we do not intend to let the user set the id.

    // Rule of thumb: compare by values
    return
        // Strings can be compared by their values in this manner
        (title != original.title) ||
            (authors != original.authors) ||
            documentPointer.userMadeAChange();
  }
}
