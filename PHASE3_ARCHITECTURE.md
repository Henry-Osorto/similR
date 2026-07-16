
# similR — Phase 3 architecture

## Runtime flow

```text
Research description
        ↓
prepare_user_query()
        ↓
select_engine()
        ↓
load_lexical_index()
        ↓
Five dimension queries
        ↓
TF-IDF + BM25 + ExactMatch
        ↓
Dimension weights
        ↓
Top-n institutional articles
```

## Data and cache separation

```text
GitHub Release
└── university_articles_YYYY-MM.duckdb

User data directory
├── active DuckDB database
└── manifest.json

User cache directory
└── lexical-index/
    └── lexical-index-<database-key>.rds
```

The DuckDB file stores normalized lexical documents and tokens. The sparse matrices are reconstructed once and cached locally. This avoids distributing redundant sparse matrices while preserving fast repeated searches.

## Dimension score

```text
0.45 × TF-IDF cosine
+ 0.35 × BM25
+ 0.20 × exact term/token coverage
```

## Default dimension weights

```text
Theme   0.20
Method  0.22
Data    0.10
Context 0.23
Purpose 0.25
```

Weights for empty fields become zero and the remaining weights are renormalized.
