required_database_tables <- function() {
  c("articles", "embeddings", "lexical_documents", "database_metadata")
}

required_article_columns <- function() {
  article_release_columns()
}

open_database <- function(path = local_database_path(must_exist = TRUE), read_only = TRUE) {
  DBI::dbConnect(duckdb::duckdb(), dbdir = path, read_only = isTRUE(read_only))
}

close_database <- function(connection) {
  if (!is.null(connection) && DBI::dbIsValid(connection)) DBI::dbDisconnect(connection, shutdown = TRUE)
  invisible(NULL)
}

check_required_tables <- function(connection) {
  available <- DBI::dbListTables(connection)
  missing <- setdiff(required_database_tables(), available)
  if (length(missing) > 0L) {
    rlang::abort(
      c("La base DuckDB no tiene todas las tablas requeridas.", "x" = paste("Faltan:", paste(missing, collapse = ", "))),
      class = "similR_invalid_database_schema"
    )
  }
  invisible(TRUE)
}

read_database_metadata <- function(connection) {
  metadata <- DBI::dbGetQuery(connection, "SELECT key, value FROM database_metadata")
  if (!all(c("key", "value") %in% names(metadata))) {
    rlang::abort("La tabla `database_metadata` debe contener `key` y `value`.", class = "similR_invalid_database_schema")
  }
  stats::setNames(as.list(as.character(metadata$value)), metadata$key)
}

validate_manifest <- function(manifest) {
  required <- c(
    "data_version", "published_at", "database_file", "database_schema_version",
    "number_of_articles", "embedding_model", "embedding_dimensions",
    "embedding_normalized", "query_prefix", "passage_prefix",
    "minimum_package_version", "sha256"
  )
  missing <- setdiff(required, names(manifest))
  if (length(missing) > 0L) {
    rlang::abort(c("El manifest no contiene todos los campos requeridos.", "x" = paste("Faltan:", paste(missing, collapse = ", "))), class = "similR_invalid_manifest")
  }
  manifest$embedding_status <- manifest$embedding_status %||% ifelse(as.integer(manifest$embedding_dimensions) > 0L, "complete", "absent")
  if (!manifest$embedding_status %in% c("absent", "partial", "complete")) {
    rlang::abort("`embedding_status` debe ser absent, partial o complete.", class = "similR_invalid_manifest")
  }
  if (!grepl("^[0-9]{4}\\.[0-9]{2}$", manifest$data_version)) {
    rlang::abort("`data_version` debe usar el formato YYYY.MM.", class = "similR_invalid_manifest")
  }
  if (!identical(basename(manifest$database_file), manifest$database_file)) {
    rlang::abort("`database_file` debe contener solo el nombre del archivo.", class = "similR_invalid_manifest")
  }
  if (!grepl(package_config()$database_asset_pattern, manifest$database_file)) {
    rlang::abort("El nombre de la base no coincide con el patrón configurado.", class = "similR_invalid_manifest")
  }
  hash <- tolower(sub("^sha256:", "", manifest$sha256))
  if (!grepl("^[a-f0-9]{64}$", hash)) {
    rlang::abort("`sha256` no es un hash SHA-256 válido.", class = "similR_invalid_manifest")
  }
  manifest$sha256 <- hash
  raw_normalized <- manifest$embedding_normalized
  manifest$number_of_articles <- as.numeric(manifest$number_of_articles)
  manifest$embedding_dimensions <- as.integer(manifest$embedding_dimensions)
  if (is.na(manifest$number_of_articles) || manifest$number_of_articles < 0) {
    rlang::abort("`number_of_articles` debe ser no negativo.", class = "similR_invalid_manifest")
  }
  minimum_dimensions <- if (manifest$embedding_status == "absent") 0L else 1L
  if (is.na(manifest$embedding_dimensions) || manifest$embedding_dimensions < minimum_dimensions) {
    rlang::abort("`embedding_dimensions` no es compatible con `embedding_status`.", class = "similR_invalid_manifest")
  }
  if (!is.logical(raw_normalized) || length(raw_normalized) != 1L || is.na(raw_normalized)) {
    rlang::abort("`embedding_normalized` debe ser TRUE o FALSE.", class = "similR_invalid_manifest")
  }
  manifest$embedding_normalized <- raw_normalized
  current <- installed_package_version()
  if (utils::compareVersion(current, as.character(manifest$minimum_package_version)) < 0L) {
    rlang::abort(
      c("La base requiere una versión más reciente de similR.", "x" = paste("Versión instalada:", current), "i" = paste("Versión mínima:", manifest$minimum_package_version)),
      class = "similR_package_version_incompatible"
    )
  }
  if (!identical(as.character(manifest$database_schema_version), as.character(package_config()$schema_version))) {
    rlang::abort("La versión del esquema de datos no es compatible.", class = "similR_database_schema_incompatible")
  }
  manifest
}

validate_database <- function(path, manifest = NULL) {
  if (!file.exists(path)) rlang::abort(sprintf("No existe la base `%s`.", path), class = "similR_database_not_found")
  if (!is.null(manifest)) manifest <- validate_manifest(manifest)
  connection <- tryCatch(
    open_database(path, read_only = TRUE),
    error = function(e) rlang::abort(c("No fue posible abrir la base DuckDB.", "x" = conditionMessage(e)), class = "similR_invalid_database", parent = e)
  )
  on.exit(close_database(connection), add = TRUE)
  check_required_tables(connection)

  missing_articles <- setdiff(required_article_columns(), DBI::dbListFields(connection, "articles"))
  if (length(missing_articles) > 0L) {
    rlang::abort(c("La tabla `articles` no tiene todas las columnas requeridas.", "x" = paste("Faltan:", paste(missing_articles, collapse = ", "))), class = "similR_invalid_database_schema")
  }
  required_embeddings <- c("article_id", "dimension", "model_name", "embedding_dimensions", "normalized", "embedding_blob", "content_hash")
  missing_embeddings <- setdiff(required_embeddings, DBI::dbListFields(connection, "embeddings"))
  if (length(missing_embeddings) > 0L) rlang::abort("La tabla `embeddings` tiene un esquema inválido.", class = "similR_invalid_database_schema")
  required_lexical <- c("article_id", "dimension", "normalized_text", "tokens_json", "document_length", "exact_terms", "content_hash")
  missing_lexical <- setdiff(required_lexical, DBI::dbListFields(connection, "lexical_documents"))
  if (length(missing_lexical) > 0L) rlang::abort("La tabla `lexical_documents` tiene un esquema inválido.", class = "similR_invalid_database_schema")

  metadata <- read_database_metadata(connection)
  article_stats <- DBI::dbGetQuery(connection, "SELECT COUNT(*) AS n, COUNT(DISTINCT article_id) AS unique_n FROM articles")
  number_of_articles <- as.numeric(article_stats$n[[1L]])
  if (article_stats$n[[1L]] != article_stats$unique_n[[1L]]) rlang::abort("Existen article_id duplicados.", class = "similR_invalid_database_schema")
  lexical_duplicates <- DBI::dbGetQuery(connection, "SELECT COUNT(*) AS n FROM (SELECT article_id, dimension, COUNT(*) c FROM lexical_documents GROUP BY article_id, dimension HAVING COUNT(*) > 1)")$n[[1L]]
  if (lexical_duplicates > 0L) rlang::abort("Existen documentos lexicales duplicados.", class = "similR_invalid_database_schema")
  lexical_count <- as.numeric(DBI::dbGetQuery(connection, "SELECT COUNT(*) AS n FROM lexical_documents")$n[[1L]])
  expected_lexical <- number_of_articles * length(package_config()$dimensions)
  if (lexical_count != expected_lexical) {
    rlang::abort("La tabla lexical_documents no contiene cinco dimensiones por artículo.", class = "similR_invalid_database_schema")
  }
  invalid_lexical_dimensions <- DBI::dbGetQuery(
    connection,
    paste0(
      "SELECT COUNT(*) AS n FROM lexical_documents WHERE dimension NOT IN (",
      paste(sprintf("'%s'", package_config()$dimensions), collapse = ","),
      ")"
    )
  )$n[[1L]]
  if (invalid_lexical_dimensions > 0L) rlang::abort("Existen dimensiones lexicales inválidas.", class = "similR_invalid_database_schema")

  orphan_embeddings <- DBI::dbGetQuery(connection, "SELECT COUNT(*) AS n FROM embeddings e LEFT JOIN articles a ON e.article_id = a.article_id WHERE a.article_id IS NULL")$n[[1L]]
  if (orphan_embeddings > 0L) rlang::abort("Existen embeddings huérfanos.", class = "similR_invalid_database_schema")
  embedding_count <- as.numeric(DBI::dbGetQuery(connection, "SELECT COUNT(*) AS n FROM embeddings")$n[[1L]])
  embedding_duplicates <- DBI::dbGetQuery(connection, "SELECT COUNT(*) AS n FROM (SELECT article_id, dimension, COUNT(*) c FROM embeddings GROUP BY article_id, dimension HAVING COUNT(*) > 1)")$n[[1L]]
  if (embedding_duplicates > 0L) rlang::abort("Existen embeddings duplicados.", class = "similR_invalid_database_schema")

  if (!is.null(manifest) && !isTRUE(all.equal(number_of_articles, manifest$number_of_articles))) {
    rlang::abort("El número de artículos no coincide con el manifest.", class = "similR_database_manifest_mismatch")
  }
  if (!is.null(manifest)) {
    expected_embeddings <- number_of_articles * length(package_config()$dimensions)
    if (manifest$embedding_status == "absent" && embedding_count != 0L) {
      rlang::abort("El manifest declara embeddings ausentes, pero la tabla no está vacía.", class = "similR_database_manifest_mismatch")
    }
    if (manifest$embedding_status == "complete" && embedding_count != expected_embeddings) {
      rlang::abort("El manifest declara embeddings completos, pero faltan registros.", class = "similR_database_manifest_mismatch")
    }
    if (manifest$embedding_status == "partial" && (embedding_count <= 0L || embedding_count >= expected_embeddings)) {
      rlang::abort("El estado parcial de embeddings no coincide con la tabla.", class = "similR_database_manifest_mismatch")
    }
  }
  if (!is.null(metadata$database_schema_version) && !identical(as.character(metadata$database_schema_version), package_config()$schema_version)) {
    rlang::abort("La metadata interna declara un esquema incompatible.", class = "similR_database_schema_incompatible")
  }
  if (!is.null(manifest) && !is.null(metadata$data_version) && !identical(as.character(metadata$data_version), as.character(manifest$data_version))) {
    rlang::abort("La versión interna no coincide con el manifest.", class = "similR_database_manifest_mismatch")
  }

  structure(
    list(valid = TRUE, path = fs::path_abs(path), tables = DBI::dbListTables(connection), number_of_articles = number_of_articles, metadata = metadata),
    class = "similR_database_validation"
  )
}
