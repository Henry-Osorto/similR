article_release_columns <- function() {
  c(
    "article_id", "title", "title_normalized", "authors", "abstract", "keywords",
    "doi", "doi_normalized", "year", "source_title", "theme_text", "purpose_text",
    "method_text", "data_text", "context_text", "missing_abstract", "content_hash",
    "created_at", "updated_at", "theme_source", "theme_confidence",
    "purpose_source", "purpose_confidence", "method_source", "method_confidence",
    "data_source", "data_confidence", "context_source", "context_confidence",
    "dimension_language"
  )
}

prepare_articles_for_release <- function(data) {
  if (!all(paste0(package_config()$dimensions, "_text") %in% names(data))) {
    data <- build_dimension_texts(data)
  }
  required <- article_release_columns()
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    rlang::abort(paste("Faltan columnas para construir la base:", paste(missing, collapse = ", ")))
  }
  data |>
    dplyr::select(dplyr::all_of(required)) |>
    dplyr::distinct(.data$article_id, .keep_all = TRUE) |>
    dplyr::arrange(.data$article_id)
}

create_database_tables <- function(connection) {
  DBI::dbExecute(connection, paste(
    "CREATE TABLE articles (",
    "article_id VARCHAR PRIMARY KEY, title VARCHAR, title_normalized VARCHAR,",
    "authors VARCHAR, abstract VARCHAR, keywords VARCHAR, doi VARCHAR,",
    "doi_normalized VARCHAR, year INTEGER, source_title VARCHAR,",
    "theme_text VARCHAR, purpose_text VARCHAR, method_text VARCHAR,",
    "data_text VARCHAR, context_text VARCHAR, missing_abstract BOOLEAN,",
    "content_hash VARCHAR, created_at VARCHAR, updated_at VARCHAR,",
    "theme_source VARCHAR, theme_confidence DOUBLE,",
    "purpose_source VARCHAR, purpose_confidence DOUBLE,",
    "method_source VARCHAR, method_confidence DOUBLE,",
    "data_source VARCHAR, data_confidence DOUBLE,",
    "context_source VARCHAR, context_confidence DOUBLE,",
    "dimension_language VARCHAR)"
  ))
  DBI::dbExecute(connection, paste(
    "CREATE TABLE embeddings (",
    "article_id VARCHAR, dimension VARCHAR, model_name VARCHAR,",
    "embedding_dimensions INTEGER, normalized BOOLEAN,",
    "embedding_blob VARCHAR, content_hash VARCHAR)"
  ))
  DBI::dbExecute(connection, paste(
    "CREATE TABLE lexical_documents (",
    "article_id VARCHAR, dimension VARCHAR, normalized_text VARCHAR,",
    "tokens_json VARCHAR, document_length INTEGER, exact_terms VARCHAR,",
    "content_hash VARCHAR)"
  ))
  DBI::dbExecute(connection, "CREATE TABLE database_metadata (key VARCHAR PRIMARY KEY, value VARCHAR)")
}

write_database_indexes <- function(connection) {
  statements <- c(
    "CREATE INDEX idx_articles_doi ON articles(doi_normalized)",
    "CREATE INDEX idx_articles_year ON articles(year)",
    "CREATE INDEX idx_embeddings_article_dimension ON embeddings(article_id, dimension)",
    "CREATE INDEX idx_lexical_article_dimension ON lexical_documents(article_id, dimension)"
  )
  for (statement in statements) DBI::dbExecute(connection, statement)
  invisible(TRUE)
}

embedding_release_status <- function(embeddings, number_of_articles) {
  expected <- number_of_articles * length(package_config()$dimensions)
  actual <- nrow(embeddings)
  status <- if (actual == 0L) "absent" else if (actual == expected) "complete" else "partial"
  dimensions <- if (actual == 0L) integer() else unique(as.integer(embeddings$embedding_dimensions))
  if (length(dimensions) > 1L) rlang::abort("La tabla de embeddings contiene dimensiones incompatibles.")
  dimension_value <- if (length(dimensions) == 0L) 0L else dimensions[[1L]]
  normalized <- if (actual == 0L) FALSE else all(embeddings$normalized)
  list(status = status, expected = expected, actual = actual, dimensions = dimension_value, normalized = normalized)
}

reuse_previous_embeddings <- function(previous_database, comparison, model_name) {
  if (!is.character(previous_database) || length(previous_database) != 1L) {
    return(empty_embeddings_table())
  }
  previous <- load_previous_embeddings(previous_database)
  if (nrow(previous) == 0L) return(previous)
  unchanged <- comparison$table$article_id[comparison$table$status == "unchanged"]
  previous |>
    dplyr::filter(
      .data$article_id %in% unchanged,
      .data$model_name == model_name,
      .data$dimension %in% package_config()$dimensions,
      .data$normalized
    )
}

release_metadata <- function(data_version, data, model_name, embedding_info, comparison) {
  values <- list(
    data_version = data_version,
    published_at = as.character(Sys.Date()),
    database_schema_version = package_config()$schema_version,
    number_of_articles = nrow(data),
    embedding_model = model_name,
    embedding_status = embedding_info$status,
    embedding_dimensions = embedding_info$dimensions,
    embedding_normalized = embedding_info$normalized,
    query_prefix = "query: ",
    passage_prefix = "passage: ",
    minimum_package_version = package_config()$minimum_package_version,
    lexical_index_version = package_config()$lexical_index_version,
    lexical_components = "tfidf:0.45,bm25:0.35,exact:0.20",
    articles_new = comparison$summary$new,
    articles_modified = comparison$summary$modified,
    articles_unchanged = comparison$summary$unchanged,
    articles_removed = comparison$summary$removed
  )
  tibble::tibble(
    key = names(values),
    value = vapply(values, as.character, character(1))
  )
}

write_release_notes <- function(path, data_version, comparison, embedding_info) {
  lines <- c(
    paste0("# Base bibliográfica ", data_version),
    "",
    paste0("Fecha de construcción: ", as.character(Sys.Date())),
    "",
    "## Cambios",
    "",
    paste0("- Artículos nuevos: ", comparison$summary$new),
    paste0("- Artículos modificados: ", comparison$summary$modified),
    paste0("- Artículos sin cambios: ", comparison$summary$unchanged),
    paste0("- Artículos eliminados: ", comparison$summary$removed),
    paste0("- Embeddings reutilizados: ", embedding_info$reused %||% 0L),
    paste0("- Embeddings generados o incorporados: ", embedding_info$regenerated %||% 0L),
    paste0("- Embeddings totales en la base: ", embedding_info$actual),
    paste0("- Estado de embeddings: ", embedding_info$status),
    paste0("- Versión del índice lexical: ", package_config()$lexical_index_version),
    "- Motor lexical: 0.45 TF-IDF + 0.35 BM25 + 0.20 coincidencias exactas",
    "",
    "La base fue generada por similR y debe publicarse junto con manifest.json y checksums.txt."
  )
  writeLines(lines, path, useBytes = TRUE)
  invisible(path)
}

#' Build a versioned DuckDB data release
#'
#' @param data Processed article data, preferably from [build_dimension_texts()].
#' @param previous_database Optional previous DuckDB file used for incremental comparison.
#' @param data_version Data version in `YYYY.MM` format.
#' @param model_name Embedding model identifier recorded in metadata.
#' @param output_dir Directory where the release files will be written.
#' @param embeddings Optional data frame with `article_id`, `dimension`, and a
#'   list-column named `embedding`. A valid lexical Release may be built without embeddings.
#' @param overwrite Whether an existing release directory may be replaced.
#'
#' @return An object of class `similR_release`.
#' @export
build_database_release <- function(
    data,
    previous_database = NULL,
    data_version,
    model_name = package_config()$default_model,
    output_dir,
    embeddings = NULL,
    overwrite = FALSE) {
  ensure_data_frame(data)
  ensure_scalar_character(data_version, "data_version")
  ensure_scalar_character(model_name, "model_name")
  ensure_scalar_character(output_dir, "output_dir")
  if (!grepl("^[0-9]{4}\\.[0-9]{2}$", data_version)) {
    rlang::abort("`data_version` debe usar el formato YYYY.MM.")
  }

  output_dir <- fs::path_abs(output_dir)
  if (dir.exists(output_dir) && length(fs::dir_ls(output_dir, fail = FALSE)) > 0L) {
    if (!isTRUE(overwrite)) {
      rlang::abort("El directorio de salida no está vacío; use `overwrite = TRUE`.")
    }
    fs::dir_delete(output_dir)
  }
  fs::dir_create(output_dir, recurse = TRUE)

  articles <- prepare_articles_for_release(data)
  comparison <- compare_database_versions(articles, previous_database)
  articles <- merge_previous_timestamps(articles, previous_database, comparison)
  lexical_documents <- build_lexical_documents(articles)

  reusable <- reuse_previous_embeddings(previous_database, comparison, model_name)
  supplied <- standardize_embeddings_input(embeddings, articles, model_name)
  embedding_table <- dplyr::bind_rows(reusable, supplied) |>
    dplyr::filter(.data$article_id %in% articles$article_id) |>
    dplyr::distinct(.data$article_id, .data$dimension, .keep_all = TRUE)
  embedding_info <- embedding_release_status(embedding_table, nrow(articles))
  embedding_info$reused <- nrow(reusable)
  embedding_info$regenerated <- nrow(supplied)

  database_file <- sprintf("university_articles_%s.duckdb", gsub("\\.", "-", data_version))
  database_path <- fs::path(output_dir, database_file)
  manifest_path <- fs::path(output_dir, package_config()$manifest_asset)
  checksums_path <- fs::path(output_dir, package_config()$checksum_asset)
  notes_path <- fs::path(output_dir, "release_notes.md")

  connection <- DBI::dbConnect(duckdb::duckdb(), dbdir = database_path)
  database_ok <- FALSE
  on.exit({
    if (DBI::dbIsValid(connection)) DBI::dbDisconnect(connection, shutdown = TRUE)
    if (!database_ok && file.exists(database_path)) unlink(database_path, force = TRUE)
  }, add = TRUE)

  DBI::dbWithTransaction(connection, {
    create_database_tables(connection)
    if (nrow(articles) > 0L) DBI::dbAppendTable(connection, "articles", as.data.frame(articles))
    if (nrow(embedding_table) > 0L) DBI::dbAppendTable(connection, "embeddings", as.data.frame(embedding_table))
    if (nrow(lexical_documents) > 0L) DBI::dbAppendTable(connection, "lexical_documents", as.data.frame(lexical_documents))
    metadata <- release_metadata(data_version, articles, model_name, embedding_info, comparison)
    DBI::dbAppendTable(connection, "database_metadata", as.data.frame(metadata))
    write_database_indexes(connection)
  })
  DBI::dbDisconnect(connection, shutdown = TRUE)
  database_ok <- TRUE

  hash <- sha256_file(database_path)
  manifest <- list(
    data_version = data_version,
    published_at = as.character(Sys.Date()),
    database_file = database_file,
    database_schema_version = package_config()$schema_version,
    number_of_articles = nrow(articles),
    embedding_model = model_name,
    embedding_status = embedding_info$status,
    embedding_dimensions = embedding_info$dimensions,
    embedding_normalized = embedding_info$normalized,
    query_prefix = "query: ",
    passage_prefix = "passage: ",
    minimum_package_version = package_config()$minimum_package_version,
    lexical_index_version = package_config()$lexical_index_version,
    lexical_components = "tfidf:0.45,bm25:0.35,exact:0.20",
    sha256 = hash
  )
  jsonlite::write_json(manifest, manifest_path, pretty = TRUE, auto_unbox = TRUE, na = "null")
  writeLines(paste(hash, database_file), checksums_path, useBytes = TRUE)
  write_release_notes(notes_path, data_version, comparison, embedding_info)

  release <- structure(
    list(
      output_dir = output_dir,
      database_path = database_path,
      manifest_path = manifest_path,
      checksums_path = checksums_path,
      release_notes_path = notes_path,
      manifest = manifest,
      comparison = comparison,
      embedding_summary = embedding_info
    ),
    class = "similR_release"
  )
  release$validation <- validate_release(release)
  release
}

#' @export
print.similR_release <- function(x, ...) {
  cat("Release de datos similR\n\n")
  cat(sprintf("Versión: %s\n", x$manifest$data_version))
  cat(sprintf("Artículos: %s\n", format(x$manifest$number_of_articles, big.mark = ",")))
  cat(sprintf("Embeddings: %s\n", x$manifest$embedding_status))
  cat(sprintf("Directorio: %s\n", x$output_dir))
  invisible(x)
}
