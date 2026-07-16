metadata_as_logical <- function(x, default = FALSE) {
  if (is.null(x) || length(x) == 0L || is.na(x[[1L]])) return(default)
  tolower(as.character(x[[1L]])) %in% c("true", "1", "yes", "sí")
}

metadata_as_integer <- function(x, default = NA_integer_) {
  if (is.null(x) || length(x) == 0L) return(default)
  value <- suppressWarnings(as.integer(x[[1L]]))
  if (is.na(value)) default else value
}

semantic_database_metadata <- function(
    database_path = local_database_path(must_exist = TRUE)) {
  validation <- validate_database(database_path)
  metadata <- validation$metadata
  list(
    database_path = fs::path_abs(database_path),
    number_of_articles = validation$number_of_articles,
    model_name = metadata$embedding_model %||% NA_character_,
    status = metadata$embedding_status %||% "absent",
    dimensions = metadata_as_integer(metadata$embedding_dimensions, 0L),
    normalized = metadata_as_logical(metadata$embedding_normalized, FALSE),
    query_prefix = metadata$query_prefix %||% NA_character_,
    passage_prefix = metadata$passage_prefix %||% NA_character_,
    semantic_index_version = metadata$semantic_index_version %||% NA_character_
  )
}

load_embeddings <- function(
    database_path = local_database_path(must_exist = TRUE),
    dimensions = package_config()$dimensions) {
  dimensions <- intersect(as.character(dimensions), package_config()$dimensions)
  if (length(dimensions) == 0L) return(empty_embeddings_table())
  connection <- open_database(database_path, read_only = TRUE)
  on.exit(close_database(connection), add = TRUE)
  rows <- tibble::as_tibble(DBI::dbReadTable(connection, "embeddings"))
  rows |>
    dplyr::filter(.data$dimension %in% .env$dimensions)
}

load_embedding_matrix <- function(
    database_path,
    dimension,
    article_ids,
    expected_model = NULL,
    expected_dimensions = NULL,
    require_normalized = TRUE) {
  ensure_scalar_character(database_path, "database_path")
  ensure_scalar_character(dimension, "dimension")
  if (!dimension %in% package_config()$dimensions) {
    rlang::abort("La dimensión semántica no es válida.")
  }
  article_ids <- as.character(article_ids)
  if (length(article_ids) == 0L) {
    return(matrix(numeric(), nrow = 0L, ncol = expected_dimensions %||% 0L))
  }

  rows <- load_embeddings(database_path, dimensions = dimension)
  rows <- rows[match(article_ids, rows$article_id), , drop = FALSE]
  if (nrow(rows) != length(article_ids) || anyNA(rows$article_id)) {
    rlang::abort(
      sprintf("Faltan embeddings de la dimensión `%s` para algunos artículos.", dimension),
      class = "similR_incomplete_embeddings"
    )
  }
  if (anyDuplicated(rows$article_id)) {
    rlang::abort("La matriz semántica contiene artículos duplicados.")
  }
  if (!is.null(expected_model) && any(rows$model_name != expected_model)) {
    rlang::abort("La tabla contiene embeddings generados con un modelo diferente.")
  }
  if (isTRUE(require_normalized) && !all(rows$normalized)) {
    rlang::abort("Los embeddings almacenados no están normalizados.")
  }

  dimensions <- unique(as.integer(rows$embedding_dimensions))
  if (length(dimensions) != 1L || is.na(dimensions[[1L]]) || dimensions[[1L]] < 1L) {
    rlang::abort("La dimensión de los embeddings almacenados es inválida.")
  }
  if (!is.null(expected_dimensions) && dimensions[[1L]] != as.integer(expected_dimensions)) {
    rlang::abort("La dimensión de la matriz no coincide con la metadata.")
  }

  vectors <- lapply(rows$embedding_blob, deserialize_embedding_vector)
  if (any(lengths(vectors) != dimensions[[1L]])) {
    rlang::abort("Existen vectores serializados con longitudes incompatibles.")
  }
  matrix <- do.call(rbind, vectors)
  storage.mode(matrix) <- "double"
  rownames(matrix) <- article_ids
  matrix
}

validate_semantic_database_compatibility <- function(
    database_path = local_database_path(must_exist = TRUE),
    model_name = NULL) {
  metadata <- semantic_database_metadata(database_path)
  expected_model <- model_name %||% metadata$model_name

  problems <- character()
  if (!identical(metadata$status, "complete")) {
    problems <- c(problems, "la base no contiene embeddings completos")
  }
  if (is_blank_string(metadata$model_name)) {
    problems <- c(problems, "la base no declara el modelo de embeddings")
  }
  if (!is.null(expected_model) && !identical(metadata$model_name, expected_model)) {
    problems <- c(problems, "el modelo solicitado no coincide con el modelo de la base")
  }
  if (metadata$dimensions < 1L) {
    problems <- c(problems, "la dimensión de los embeddings es inválida")
  }
  if (!isTRUE(metadata$normalized)) {
    problems <- c(problems, "los embeddings de la base no están normalizados")
  }
  if (!identical(metadata$query_prefix, package_config()$query_prefix)) {
    problems <- c(problems, "el prefijo de consultas es incompatible")
  }
  if (!identical(metadata$passage_prefix, package_config()$passage_prefix)) {
    problems <- c(problems, "el prefijo de documentos es incompatible")
  }

  if (length(problems) > 0L) {
    rlang::abort(
      c(
        "La base bibliográfica no es compatible con el motor semántico.",
        "x" = paste(problems, collapse = "; "),
        "i" = "Reconstruya la Release con `generate_article_embeddings()` y `build_database_release()`."
      ),
      class = "similR_semantic_database_incompatible"
    )
  }
  metadata
}

semantic_database_ready <- function(
    database_path = local_database_path(must_exist = TRUE),
    model_name = NULL) {
  tryCatch({
    validate_semantic_database_compatibility(database_path, model_name)
    TRUE
  }, error = function(e) FALSE)
}

.semantic_index_state <- new.env(parent = emptyenv())
.semantic_index_state$key <- NULL
.semantic_index_state$index <- NULL

semantic_database_key <- function(path) {
  path <- fs::path_abs(path)
  info <- file.info(path)
  hash_text(
    path,
    as.character(info$size %||% 0),
    format(info$mtime, "%Y-%m-%dT%H:%M:%OS6", tz = "UTC"),
    package_config()$semantic_index_version
  )
}

clear_semantic_memory_cache <- function() {
  .semantic_index_state$key <- NULL
  .semantic_index_state$index <- NULL
  invisible(TRUE)
}

build_semantic_index <- function(
    database_path = local_database_path(must_exist = TRUE),
    use_cache = TRUE) {
  ensure_scalar_character(database_path, "database_path")
  metadata <- validate_semantic_database_compatibility(database_path)
  key <- semantic_database_key(database_path)

  if (isTRUE(use_cache) &&
      identical(.semantic_index_state$key, key) &&
      inherits(.semantic_index_state$index, "similR_semantic_index")) {
    return(.semantic_index_state$index)
  }

  articles <- load_articles(database_path)
  article_ids <- articles$article_id
  matrices <- stats::setNames(lapply(package_config()$dimensions, function(dimension) {
    load_embedding_matrix(
      database_path = database_path,
      dimension = dimension,
      article_ids = article_ids,
      expected_model = metadata$model_name,
      expected_dimensions = metadata$dimensions,
      require_normalized = TRUE
    )
  }), package_config()$dimensions)

  index <- structure(
    list(
      key = key,
      database_path = fs::path_abs(database_path),
      built_at = utc_now(),
      index_version = package_config()$semantic_index_version,
      metadata = metadata,
      articles = articles,
      dimensions = matrices
    ),
    class = "similR_semantic_index"
  )
  if (isTRUE(use_cache)) {
    .semantic_index_state$key <- key
    .semantic_index_state$index <- index
  }
  index
}

load_semantic_index <- function(
    database_path = local_database_path(must_exist = TRUE),
    use_cache = TRUE) {
  build_semantic_index(database_path = database_path, use_cache = use_cache)
}
