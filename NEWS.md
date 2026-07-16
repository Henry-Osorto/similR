
# similR 0.3.0.9000

## Fase 3

- Added a fully local lexical recommendation engine.
- Added sparse per-dimension lexical indexes cached in the user directory.
- Added TF-IDF cosine similarity.
- Added BM25 ranking with document-length normalization.
- Added exact matching for methods, countries, populations, databases, and DOI terms.
- Added automatic normalization of dimension weights when fields are empty.
- Added `recommend_articles()` as the programmatic recommendation interface.
- Added year, source, author, DOI, and article identifier filters.
- Added deterministic recommendation explanations.
- Replaced the placeholder Shiny screen with a modular recommendation application.
- Added searchable and sortable results, CSV download, and article detail modals.
- Added lexical, ranking, query, cache, and Shiny module tests.

# similR 0.2.0.9000

## Fase 2

- Renamed the package from `UniLitR` to `similR`.
- Added generic bibliographic import.
- Added Scopus-compatible processing and column mapping.
- Added DOI, title, author and keyword normalization.
- Added deterministic duplicate consolidation and possible-duplicate reports.
- Added stable SHA-256 article identifiers and content hashes.
- Added multilingual rule-based dimension text construction.
- Added incremental comparison with previous DuckDB databases.
- Added lexical-document preparation.
- Added versioned DuckDB Release construction and validation.
- Added optional reuse and storage of precomputed embeddings.

# similR 0.1.0.9000

- Initial local database lifecycle and GitHub Release support.
