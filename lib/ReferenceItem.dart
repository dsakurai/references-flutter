import 'dart:typed_data';

class LocalBinary {

  // null indicates that the blob is null in the database
  Future<ByteBuffer?> _byteBuffer;

  Future<bool> isNullInDatabase () async {
    final ByteBuffer? b = await _byteBuffer;
    return b == null;
  }

  LocalBinary({
    required Future<ByteBuffer?> byteBuffer
  }): _byteBuffer = byteBuffer;

}

class DocumentPointer {

  // null indicates that data is not downloaded from the database.
  // The local binary of a PDF (or powerpoint etc.) can be updated, in which case this LocalBinary instance is replaced with a newly constructed one.
  LocalBinary? _local; // Note: if the actual blob is null in the database but is already in the fetch, `_local` is non-null.

  // hasn't fetched data from the database
  bool get inFetch {
    return _local != null;
  }

  DocumentPointer({
    LocalBinary? local
  }):
    _local = local
  ;

  // Used for generating a temporary reference item that can be edited by the user.
  // The copied item can be removed if the user does not edit the record.
  DocumentPointer clone() => DocumentPointer(
    local: this._local // point at the same local fetch originally.
  );
}

class ReferenceItem {
  String title;
  String authors;
  DocumentPointer documentPointer; // the actual binary might not be fetched from the database

  ReferenceItem clone() => ReferenceItem(
      title: title,
      authors: authors,
      documentPointer: documentPointer
          .clone() // although a clone, the binary points at the same blob instance (in the fetch or in the database).
      );

  void copyPropertiesFrom(ReferenceItem other) {
    title = other.title;
    authors = other.authors;
  }

  ReferenceItem({this.title = "",
                 this.authors = "",
                 required this.documentPointer,
  });

  bool matches(ReferenceItem that) {
    return
        // Strings can be compared by their values in this manner
        (title == that.title) && (authors == that.authors);
  }
}
