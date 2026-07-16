semantic_prefix <- function(type = c("query", "passage")) {
  type <- match.arg(type)
  if (identical(type, "query")) package_config()$query_prefix else package_config()$passage_prefix
}

normalize_embedding_rows <- function(x) {
  x <- as.matrix(x)
  if (nrow(x) == 0L || ncol(x) == 0L) return(x)
  norms <- sqrt(rowSums(x^2))
  norms[!is.finite(norms) | norms == 0] <- 1
  x / norms
}

#' Generate local sentence embeddings
#'
#' @param texts Character vector of texts.
#' @param type Whether texts are retrieval queries or passages.
#' @param model_name Locally downloaded Sentence Transformer model.
#' @param batch_size Positive encoding batch size.
#'
#' @return A numeric matrix with one row per input text.
#' @noRd
embed_texts <- function(
    texts,
    type = c("query", "passage"),
    model_name = package_config()$default_model,
    batch_size = 32L) {
  type <- match.arg(type)
  ensure_scalar_character(model_name, "model_name")
  if (!is.character(texts)) {
    rlang::abort("`texts` debe ser un vector de caracteres.")
  }
  if (length(texts) == 0L) {
    rlang::abort("Debe proporcionar al menos un texto.")
  }
  batch_size <- as.integer(batch_size)
  if (length(batch_size) != 1L || is.na(batch_size) || batch_size < 1L) {
    rlang::abort("`batch_size` debe ser un entero positivo.")
  }

  texts[is.na(texts)] <- ""
  texts <- trimws(texts)
  blank <- which(!nzchar(texts))
  if (length(blank) > 0L) {
    rlang::abort(
      c(
        "No se pueden generar embeddings para textos vacíos.",
        "x" = paste("Posiciones:", paste(blank, collapse = ", "))
      ),
      class = "similR_empty_embedding_text"
    )
  }

  model <- get_embedding_model(model_name)
  input_texts <- paste0(semantic_prefix(type), texts)
  encoded <- tryCatch(
    model$encode(
      as.list(input_texts),
      batch_size = batch_size,
      normalize_embeddings = TRUE,
      convert_to_numpy = TRUE,
      show_progress_bar = isTRUE(interactive() && length(texts) > batch_size)
    ),
    error = function(e) {
      rlang::abort(
        c(
          "No fue posible generar los embeddings.",
          "x" = conditionMessage(e)
        ),
        class = "similR_embedding_error",
        parent = e
      )
    }
  )

  encoded <- if (reticulate::is_py_object(encoded)) {
    reticulate::py_to_r(encoded)
  } else {
    encoded
  }
  encoded <- as.matrix(encoded)
  if (length(texts) == 1L && nrow(encoded) != 1L) {
    encoded <- matrix(as.numeric(encoded), nrow = 1L)
  }
  if (nrow(encoded) != length(texts) || ncol(encoded) < 1L) {
    rlang::abort(
      "El modelo devolvió una matriz de dimensiones incompatibles.",
      class = "similR_embedding_shape_error"
    )
  }
  if (any(!is.finite(encoded))) {
    rlang::abort(
      "El modelo devolvió valores no finitos.",
      class = "similR_embedding_nonfinite"
    )
  }

  encoded <- normalize_embedding_rows(encoded)
  attr(encoded, "model_name") <- model_name
  attr(encoded, "embedding_type") <- type
  encoded
}

previous_semantic_configuration <- function(previous_database) {
  if (is.null(previous_database) || !file.exists(previous_database)) return(NULL)
  tryCatch({
    validation <- validate_database(previous_database)
    metadata <- validation$metadata
    list(
      model_name = metadata$embedding_model %||% NA_character_,
      status = metadata$embedding_status %||% "absent",
      dimensions = metadata_as_integer(metadata$embedding_dimensions, 0L),
      normalized = metadata_as_logical(metadata$embedding_normalized, FALSE),
      query_prefix = metadata$query_prefix %||% NA_character_,
      passage_prefix = metadata$passage_prefix %||% NA_character_,
      semantic_index_version = metadata$semantic_index_version %||% NA_character_
    )
  }, error = function(e) NULL)
}

previous_embeddings_reusable <- function(previous_database, model_name) {
  previous <- previous_semantic_configuration(previous_database)
  !is.null(previous) &&
    identical(previous$model_name, model_name) &&
    previous$dimensions > 0L &&
    isTRUE(previous$normalized) &&
    identical(previous$query_prefix, package_config()$query_prefix) &&
    identical(previous$passage_prefix, package_config()$passage_prefix) &&
    identical(
      previous$semantic_index_version,
      package_config()$semantic_index_version
    ) &&
    previous$status %in% c("partial", "complete")
}

empty_generated_embeddings <- function() {
  tibble::tibble(
    article_id = character(),
    dimension = character(),
    model_name = character(),
    normalized = logical(),
    embedding = list()
  )
}

#' Generate article embeddings for a data release
#'
#' Encodes the five dimension-specific texts as passages. When a compatible
#' previous database is supplied, only new and modified articles are encoded;
#' unchanged embeddings are reused later by [build_database_release()].
#'
#' @param data Processed articles, preferably after [build_dimension_texts()].
#' @param previous_database Optional previous DuckDB database.
#' @param model_name Locally downloaded Sentence Transformer model.
#' @param batch_size Positive encoding batch size.
#'
#' @return A tibble containing a list-column named `embedding`.
#' @export
#' @examples
#' \dontrun{
#' embeddings <- generate_article_embeddings(
#'   processed_articles,
#'   model_name = "intfloat/multilingual-e5-base"
#' )
#' }
generate_article_embeddings <- function(
    data,
    previous_database = NULL,
    model_name = package_config()$default_model,
    batch_size = 32L) {
  ensure_data_frame(data)
  ensure_scalar_character(model_name, "model_name")
  articles <- prepare_articles_for_release(data)
  comparison <- compare_database_versions(articles, previous_database)

  statuses <- if (previous_embeddings_reusable(previous_database, model_name)) {
    c("new", "modified")
  } else {
    c("new", "modified", "unchanged")
  }
  target_ids <- comparison$table$article_id[comparison$table$status %in% statuses]
  target_ids <- intersect(articles$article_id, target_ids)
  if (length(target_ids) == 0L) {
    result <- empty_generated_embeddings()
    attr(result, "generation_summary") <- list(
      generated_articles = 0L,
      generated_embeddings = 0L,
      model_name = model_name
    )
    return(result)
  }

  selected <- articles[match(target_ids, articles$article_id), , drop = FALSE]
  dimensions <- package_config()$dimensions
  output <- vector("list", length(dimensions))

  for (i in seq_along(dimensions)) {
    dimension <- dimensions[[i]]
    text_column <- paste0(dimension, "_text")
    matrix <- embed_texts(
      texts = selected[[text_column]],
      type = "passage",
      model_name = model_name,
      batch_size = batch_size
    )
    output[[i]] <- tibble::tibble(
      article_id = selected$article_id,
      dimension = dimension,
      model_name = model_name,
      normalized = TRUE,
      embedding = lapply(seq_len(nrow(matrix)), function(row) {
        as.numeric(matrix[row, , drop = TRUE])
      })
    )
  }

  result <- dplyr::bind_rows(output)
  attr(result, "generation_summary") <- list(
    generated_articles = length(target_ids),
    generated_embeddings = nrow(result),
    model_name = model_name,
    embedding_dimensions = if (nrow(result) == 0L) 0L else length(result$embedding[[1L]])
  )
  result
}
