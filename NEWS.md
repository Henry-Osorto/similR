# similR 0.4.0.9000

## Fase 4

- Added an optional local semantic engine through `reticulate` and Sentence Transformers.
- Declared Python dependencies with `py_require()` while preserving package loading without Python initialization.
- Added `install_semantic_engine()`, `check_semantic_engine()`, and `download_embedding_model()`.
- Added explicit, atomic local model downloads to the user cache directory.
- Added multilingual E5 query and passage prefixes and normalized embeddings.
- Added `generate_article_embeddings()` with incremental encoding of new and modified articles.
- Added complete semantic compatibility validation for model, dimensions, prefixes, normalization, and database coverage.
- Added semantic ranking across theme, purpose, method, data, and context.
- Added automatic fallback to the lexical engine when Python, the model, or compatible embeddings are unavailable.
- Added semantic engine tests that do not require network access and conditional integration tests.
- Updated the Shiny application to expose automatic, lexical, and semantic modes.

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
- Added generic bibliographic import and Scopus-compatible processing.
- Added DOI, title, author and keyword normalization.
- Added deterministic duplicate consolidation and possible-duplicate reports.
- Added stable SHA-256 article identifiers and content hashes.
- Added multilingual rule-based dimension text construction.
- Added incremental comparison with previous DuckDB databases.
- Added lexical-document preparation and versioned DuckDB Release construction.

# similR 0.1.0.9000

- Initial local database lifecycle and GitHub Release support.
