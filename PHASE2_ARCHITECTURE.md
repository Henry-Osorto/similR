# similR — Phase 2 architecture

## Scope

Phase 2 extends the verified GitHub Release lifecycle from Phase 1 with the complete administrative data-preparation pipeline.

## Administrative flow

```text
Source files
   ↓
import_article_data()
   ↓
process_scopus()
   ├─ column normalization
   ├─ DOI/title/author cleanup
   ├─ duplicate consolidation
   ├─ stable article_id
   └─ content_hash
   ↓
build_dimension_texts()
   ├─ theme
   ├─ purpose
   ├─ method
   ├─ data
   └─ context
   ↓
compare_database_versions()
   ├─ new
   ├─ modified
   ├─ unchanged
   └─ removed
   ↓
build_database_release()
   ├─ articles
   ├─ embeddings
   ├─ lexical_documents
   ├─ database_metadata
   ├─ manifest.json
   ├─ checksums.txt
   └─ release_notes.md
   ↓
validate_release()
   ↓
GitHub Release
```

## DuckDB tables

### articles

Contains cleaned bibliographic fields, five dimension texts, extraction provenance, confidence scores, stable identifiers, content hashes, and timestamps.

### lexical_documents

Contains one row per article and dimension with normalized tokens, JSON token lists, document lengths, and exact technical/context terms. Phase 3 will derive TF-IDF and BM25 statistics from this table.

### embeddings

Uses a portable Base64 representation of serialized numeric vectors. In Phase 2 the table may be empty. A release without embeddings is marked `embedding_status = "absent"`; Phase 4 will generate and populate the complete table.

### database_metadata

Stores data version, schema version, model configuration, article counts, and incremental-change counts.

## Incremental updates

Stable `article_id` values and `content_hash` values distinguish new, modified, unchanged, and removed records. Unchanged timestamps and compatible embeddings from a previous database can be reused.
