
.lexical_state <- new.env(parent = emptyenv())
.lexical_state$key <- NULL
.lexical_state$index <- NULL

lexical_cache_dir <- function(create = TRUE) {
  path <- fs::path(user_cache_dir(create = create), "lexical-index")
  if (isTRUE(create)) fs::dir_create(path, recurse = TRUE)
  path
}

lexical_database_key <- function(path) {
  path <- fs::path_abs(path)
  info <- file.info(path)
  hash_text(
    path,
    as.character(info$size %||% 0),
    format(info$mtime, "%Y-%m-%dT%H:%M:%OS6", tz = "UTC"),
    package_config()$lexical_index_version
  )
}

lexical_cache_path <- function(key) {
  fs::path(lexical_cache_dir(), paste0("lexical-index-", key, ".rds"))
}

clear_lexical_memory_cache <- function() {
  .lexical_state$key <- NULL
  .lexical_state$index <- NULL
  invisible(TRUE)
}

load_articles <- function(path = local_database_path(must_exist = TRUE)) {
  connection <- open_database(path, read_only = TRUE)
  on.exit(close_database(connection), add = TRUE)
  tibble::as_tibble(DBI::dbGetQuery(
    connection,
    paste(
      "SELECT article_id, title, authors, abstract, keywords, doi,",
      "doi_normalized, year, source_title, theme_text, purpose_text,",
      "method_text, data_text, context_text FROM articles ORDER BY article_id"
    )
  ))
}

load_lexical_documents <- function(path = local_database_path(must_exist = TRUE)) {
  connection <- open_database(path, read_only = TRUE)
  on.exit(close_database(connection), add = TRUE)
  tibble::as_tibble(DBI::dbGetQuery(
    connection,
    paste(
      "SELECT article_id, dimension, normalized_text, tokens_json,",
      "document_length, exact_terms, content_hash",
      "FROM lexical_documents ORDER BY dimension, article_id"
    )
  ))
}

build_sparse_term_matrix <- function(tokens, vocabulary) {
  number_documents <- length(tokens)
  number_terms <- length(vocabulary)
  if (number_documents == 0L || number_terms == 0L) {
    return(Matrix::Matrix(0, nrow = number_documents, ncol = number_terms, sparse = TRUE))
  }

  token_lengths <- lengths(tokens)
  all_tokens <- unlist(tokens, use.names = FALSE)
  if (length(all_tokens) == 0L) {
    return(Matrix::Matrix(0, nrow = number_documents, ncol = number_terms, sparse = TRUE))
  }

  rows <- rep(seq_len(number_documents), times = token_lengths)
  columns <- match(all_tokens, vocabulary)
  keep <- !is.na(columns)
  Matrix::sparseMatrix(
    i = rows[keep],
    j = columns[keep],
    x = rep.int(1, sum(keep)),
    dims = c(number_documents, number_terms),
    dimnames = list(NULL, vocabulary)
  )
}

normalize_sparse_rows <- function(matrix) {
  if (nrow(matrix) == 0L || ncol(matrix) == 0L) return(matrix)
  norms <- sqrt(Matrix::rowSums(matrix * matrix))
  inverse <- ifelse(norms > 0, 1 / norms, 0)
  Matrix::Diagonal(x = inverse) %*% matrix
}

build_dimension_lexical_index <- function(rows, article_ids, dimension) {
  rows <- rows[match(article_ids, rows$article_id), , drop = FALSE]
  if (anyNA(rows$article_id)) {
    rlang::abort(
      sprintf("La dimensión `%s` no contiene todos los artículos.", dimension),
      class = "similR_invalid_lexical_index"
    )
  }

  tokens <- lapply(rows$tokens_json, parse_json_tokens)
  vocabulary <- sort(unique(unlist(tokens, use.names = FALSE)))
  vocabulary <- vocabulary[nzchar(vocabulary)]
  counts <- build_sparse_term_matrix(tokens, vocabulary)
  number_documents <- nrow(counts)
  document_frequency <- if (ncol(counts) == 0L) numeric() else {
    as.numeric(Matrix::colSums(counts > 0))
  }
  tfidf_idf <- if (length(document_frequency) == 0L) numeric() else {
    log((number_documents + 1) / (document_frequency + 1)) + 1
  }
  bm25_idf <- if (length(document_frequency) == 0L) numeric() else {
    log(1 + (number_documents - document_frequency + 0.5) / (document_frequency + 0.5))
  }

  tf <- counts
  if (length(tf@x) > 0L) tf@x <- log1p(tf@x)
  tfidf <- if (ncol(tf) == 0L) tf else tf %*% Matrix::Diagonal(x = tfidf_idf)
  tfidf <- normalize_sparse_rows(tfidf)

  document_length <- as.numeric(rows$document_length)
  average_document_length <- if (length(document_length) == 0L) 0 else mean(document_length)

  list(
    dimension = dimension,
    article_id = article_ids,
    vocabulary = vocabulary,
    counts = counts,
    tfidf = tfidf,
    tfidf_idf = tfidf_idf,
    bm25_idf = bm25_idf,
    document_length = document_length,
    average_document_length = average_document_length,
    exact_terms = lapply(rows$exact_terms, parse_semicolon_terms)
  )
}

#' Build the cached lexical index for a DuckDB database
#'
#' @param database_path Path to a valid similR DuckDB database.
#' @param use_cache Whether a disk and memory cache may be reused.
#'
#' @return An internal lexical index object.
#' @noRd
build_lexical_index <- function(
    database_path = local_database_path(must_exist = TRUE),
    use_cache = TRUE) {
  ensure_scalar_character(database_path, "database_path")
  if (!file.exists(database_path)) {
    rlang::abort(
      sprintf("No existe la base `%s`.", database_path),
      class = "similR_database_not_found"
    )
  }
  key <- lexical_database_key(database_path)

  if (isTRUE(use_cache) && identical(.lexical_state$key, key) && !is.null(.lexical_state$index)) {
    return(.lexical_state$index)
  }

  cache_path <- lexical_cache_path(key)
  if (isTRUE(use_cache) && file.exists(cache_path)) {
    cached <- tryCatch(readRDS(cache_path), error = function(e) NULL)
    if (inherits(cached, "similR_lexical_index") && identical(cached$key, key)) {
      .lexical_state$key <- key
      .lexical_state$index <- cached
      return(cached)
    }
  }

  validate_database(database_path)
  articles <- load_articles(database_path)
  documents <- load_lexical_documents(database_path)
  article_ids <- articles$article_id
  dimensions <- package_config()$dimensions
  dimension_indexes <- stats::setNames(lapply(dimensions, function(dimension) {
    rows <- documents[documents$dimension == dimension, , drop = FALSE]
    build_dimension_lexical_index(rows, article_ids, dimension)
  }), dimensions)

  index <- structure(
    list(
      key = key,
      database_path = fs::path_abs(database_path),
      built_at = utc_now(),
      index_version = package_config()$lexical_index_version,
      articles = articles,
      dimensions = dimension_indexes
    ),
    class = "similR_lexical_index"
  )

  if (isTRUE(use_cache)) {
    temporary <- tempfile("lexical-index-", tmpdir = lexical_cache_dir(), fileext = ".rds")
    saveRDS(index, temporary, compress = "gzip")
    if (file.exists(cache_path)) unlink(cache_path, force = TRUE)
    rename_or_abort(temporary, cache_path)
  }

  .lexical_state$key <- key
  .lexical_state$index <- index
  index
}

load_lexical_index <- function(
    database_path = local_database_path(must_exist = TRUE),
    use_cache = TRUE) {
  build_lexical_index(database_path = database_path, use_cache = use_cache)
}
