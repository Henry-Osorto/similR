# similR

`similR` is an R package and local Shiny application for discovering institutional scientific literature related to a new research project.

## Development status

Phase 2 includes:

- local data lifecycle and GitHub Releases;
- generic bibliographic import;
- Scopus-compatible column mapping;
- cleaning and stable identifiers;
- exact duplicate consolidation and approximate duplicate diagnostics;
- bilingual rule-based extraction of theme, purpose, method, data and context;
- incremental comparison against a previous DuckDB database;
- construction and validation of versioned DuckDB Releases;
- preparation of normalized lexical documents;
- optional storage and reuse of precomputed embeddings.

The lexical ranking engine will be added in Phase 3 and the Python semantic engine in Phase 4.

## Installation during development

```r
install.packages("pak")
pak::pkg_install("REPLACE_GITHUB_OWNER/REPLACE_GITHUB_REPOSITORY")

library(similR)
run_app(engine = "lexical")
```

## Configure the GitHub data repository

```r
options(
  similR.github_owner = "YOUR_GITHUB_USER_OR_ORGANIZATION",
  similR.github_repo = "YOUR_DATA_REPOSITORY"
)
```

These values should ultimately be placed in `R/config.R` before publishing the package.

## Build a data Release

```r
raw <- import_article_data("data-raw/input/institutional_articles.csv")

processed <- process_scopus(
  raw,
  column_map = c(
    title = "Title",
    authors = "Authors",
    abstract = "Abstract",
    author_keywords = "Keywords",
    doi = "DOI",
    year = "Year",
    source_title = "Source"
  ),
  source = "generic"
)

processed <- build_dimension_texts(processed)

release <- build_database_release(
  data = processed,
  data_version = "2026.07",
  output_dir = "release/2026.07"
)

validate_release(release)
```

The output directory contains:

```text
university_articles_2026-07.duckdb
manifest.json
checksums.txt
release_notes.md
```

Upload the first three files as assets of the same GitHub Release. `release_notes.md` can be used as the Release description.

## Privacy

The application is designed for local processing. No telemetry is implemented and user research descriptions are not sent to an external service.
