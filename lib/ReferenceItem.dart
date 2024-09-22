
class ReferenceItem
 {
  String title;
  String authors;

  ReferenceItem clone() => ReferenceItem(
    title: title,
    authors: authors
  );

  void copyPropertiesFrom(ReferenceItem other) {
    title   = other.title;
    authors = other.authors;
  }

  // Generative constor with default param values
  ReferenceItem({this.title = "", this.authors = ""});

  bool matches(ReferenceItem that) {
    return 
      // Strings are immutable, so comparison by object adresses are fine.
      (title   == that.title) &&
      (authors == that.authors)
    ;
  }
}
