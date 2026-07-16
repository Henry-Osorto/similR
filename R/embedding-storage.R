serialize_embedding_vector <- function(x) {
  if (!is.numeric(x) || length(x) == 0L || any(!is.finite(x))) {
    rlang::abort("El embedding debe ser un vector numérico finito no vacío.")
  }
  jsonlite::base64_enc(serialize(as.double(x), connection = NULL, version = 3))
}

deserialize_embedding_vector <- function(x) {
  ensure_scalar_character(x, "x")
  value <- unserialize(jsonlite::base64_dec(x))
  if (!is.numeric(value) || length(value) == 0L) {
    rlang::abort("El embedding serializado no contiene un vector numérico válido.")
  }
  as.double(value)
}

empty_embeddings_table <- function() {
  tibble::tibble(
    article_id = character(),
    dimension = character(),
    model_name = character(),
    embedding_dimensions = integer(),
    normalized = logical(),
    embedding_blob = character(),
    content_hash = character()
  )
}

standardize_embeddings_input <- function(embeddings, articles, model_name) {
  if (is.null(embeddings)) return(empty_embeddings_table())
  ensure_data_frame(embeddings, "embeddings")
  required <- c("article_id", "dimension", "embedding")
  missing <- setdiff(required, names(embeddings))
  if (length(missing) > 0L) {
    rlang::abort(paste("Faltan columnas en `embeddings`:", paste(missing, collapse = ", ")))
  }

  valid_dimensions <- package_config()$dimensions
  if (any(!embeddings$dimension %in% valid_dimensions)) {
    rlang::abort("`dimension` contiene valores no reconocidos.")
  }
  if (any(!embeddings$article_id %in% articles$article_id)) {
    rlang::abort("Existen embeddings para artículos ausentes de la base.")
  }

  vectors <- embeddings$embedding
  if (!is.list(vectors)) {
    rlang::abort("La columna `embedding` debe ser una lista de vectores numéricos.")
  }
  dimensions <- lengths(vectors)
  if (length(unique(dimensions)) != 1L || any(dimensions < 1L)) {
    rlang::abort("Todos los embeddings deben tener la misma dimensión positiva.")
  }

  normalized <- if ("normalized" %in% names(embeddings)) {
    as.logical(embeddings$normalized)
  } else {
    rep(TRUE, nrow(embeddings))
  }
  model_values <- if ("model_name" %in% names(embeddings)) {
    as.character(embeddings$model_name)
  } else {
    rep(model_name, nrow(embeddings))
  }
  model_values[is_blank_vector(model_values)] <- model_name

  content_lookup <- stats::setNames(articles$content_hash, articles$article_id)
  tibble::tibble(
    article_id = as.character(embeddings$article_id),
    dimension = as.character(embeddings$dimension),
    model_name = model_values,
    embedding_dimensions = as.integer(dimensions),
    normalized = normalized,
    embedding_blob = vapply(vectors, serialize_embedding_vector, character(1)),
    content_hash = unname(content_lookup[as.character(embeddings$article_id)])
  ) |>
    dplyr::distinct(.data$article_id, .data$dimension, .keep_all = TRUE)
}

load_previous_embeddings <- function(previous_database) {
  if (is.null(previous_database) || !file.exists(previous_database)) {
    return(empty_embeddings_table())
  }
  connection <- open_database(previous_database, read_only = TRUE)
  on.exit(close_database(connection), add = TRUE)
  if (!"embeddings" %in% DBI::dbListTables(connection)) return(empty_embeddings_table())
  tibble::as_tibble(DBI::dbReadTable(connection, "embeddings"))
}
