# references_models

This package holds shared model classes. `ReferenceItem` supports database mapping to the MariaDB/MySQL table `References` defined in `../database/create-table.sql`.

Currently supported columns (kept minimal for maintainability):
- id (INT, PK, auto-increment)
- title (VARCHAR)
- authors (VARCHAR)
- document (LONGBLOB)

APIs:
- toDbMap()/fromDbMap(): Convert between model and DB row (handles `document` BLOB, including lazy availability semantics)
- toInsertStatement()/toUpdateStatement(): Build parameterized SQL with `?` placeholders and a stable column order: title, authors, document
- selectByIdStatement()/deleteByIdStatement(): Simple read/delete builders

Notes on `document` handling:
- If `document.isLazyDataAvailable == false`, toDbMap() omits the `document` column to avoid accidentally nulling the blob on updates.
- Pass includeDocumentIfUnavailable: true to include `document: null` explicitly.
