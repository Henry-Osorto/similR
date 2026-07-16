empty_recommendation_table <- function() {
  tibble::tibble(
    rank = integer(), index = numeric(), similarity_theme = numeric(),
    similarity_method = numeric(), similarity_data = numeric(),
    similarity_context = numeric(), similarity_purpose = numeric(),
    title = character(), authors = character(), year = integer(),
    doi = character(), keywords = character(), source_title = character(),
    abstract = character(), article_id = character(), explanation = character(),
    engine = character()
  )
}

semantic_cosine_to_unit <- function(x) {
  x <- as.numeric(x)
  x[!is.finite(x)] <- -1
  pmax(0, pmin(1, (pmax(-1, pmin(1, x)) + 1) / 2))
}

rank_articles_semantic <- function(
    query,
    database_path = local_database_path(must_exist = TRUE),
    n = 20L,
    weights = NULL,
    filters = list(),
    batch_size = 32L) {
  n <- as.integer(n)
  if (length(n) != 1L || is.na(n) || n < 1L) {
    rlang::abort("`n` debe ser un entero positivo.")
  }

  semantic_index <- load_semantic_index(database_path)
  metadata <- semantic_index$metadata
  all_articles <- semantic_index$articles
  keep <- apply_article_filters(all_articles, filters)
  articles <- all_articles[keep, , drop = FALSE]
  if (nrow(articles) == 0L) return(empty_recommendation_table())

  dimensions <- package_config()$dimensions
  available <- dimensions[nzchar(trimws(query[dimensions]))]
  effective_weights <- normalize_weights(weights, available)
  query_matrix <- embed_texts(
    texts = unname(query[available]),
    type = "query",
    model_name = metadata$model_name,
    batch_size = batch_size
  )
  rownames(query_matrix) <- available

  scores <- stats::setNames(vector("list", length(dimensions)), dimensions)
  raw_cosine <- stats::setNames(vector("list", length(dimensions)), dimensions)
  article_ids <- articles$article_id

  for (dimension in dimensions) {
    if (dimension %in% available) {
      document_matrix <- semantic_index$dimensions[[dimension]][
        match(article_ids, semantic_index$articles$article_id),
        ,
        drop = FALSE
      ]
      cosine <- drop(
        document_matrix %*% query_matrix[dimension, , drop = TRUE]
      )
      raw_cosine[[dimension]] <- cosine
      scores[[dimension]] <- semantic_cosine_to_unit(cosine)
    } else {
      raw_cosine[[dimension]] <- rep(NA_real_, nrow(articles))
      scores[[dimension]] <- rep(NA_real_, nrow(articles))
    }
  }

  scores_for_index <- lapply(scores, function(x) {
    x[is.na(x)] <- 0
    x
  })
  global_score <- combine_dimension_scores(scores_for_index, effective_weights)
  theme_score <- scores$theme
  method_score <- scores$method
  data_score <- scores$data
  context_score <- scores$context
  purpose_score <- scores$purpose

  result <- articles |>
    dplyr::mutate(
      index = 100 * .env$global_score,
      similarity_theme = 100 * .env$theme_score,
      similarity_method = 100 * .env$method_score,
      similarity_data = 100 * .env$data_score,
      similarity_context = 100 * .env$context_score,
      similarity_purpose = 100 * .env$purpose_score,
      doi = dplyr::if_else(
        !is.na(.data$doi_normalized) & nzchar(.data$doi_normalized),
        .data$doi_normalized,
        .data$doi
      ),
      engine = "semantic"
    ) |>
    dplyr::arrange(
      dplyr::desc(.data$index),
      dplyr::desc(dplyr::coalesce(.data$similarity_theme, -Inf)),
      dplyr::desc(.data$year),
      .data$title
    ) |>
    dplyr::slice_head(n = n)

  result$rank <- seq_len(nrow(result))
  result$explanation <- vapply(seq_len(nrow(result)), function(i) {
    dimension_scores <- c(
      theme = result$similarity_theme[[i]],
      method = result$similarity_method[[i]],
      data = result$similarity_data[[i]],
      context = result$similarity_context[[i]],
      purpose = result$similarity_purpose[[i]]
    )
    explain_recommendation(dimension_scores, result[i, , drop = FALSE])
  }, character(1))

  result <- result |>
    dplyr::select(
      .data$rank, .data$index, .data$similarity_theme,
      .data$similarity_method, .data$similarity_data,
      .data$similarity_context, .data$similarity_purpose,
      .data$title, .data$authors, .data$year, .data$doi,
      .data$keywords, .data$source_title, .data$abstract,
      .data$article_id, .data$explanation, .data$engine
    )

  attr(result, "effective_weights") <- effective_weights
  attr(result, "semantic_cosine") <- raw_cosine
  attr(result, "embedding_model") <- metadata$model_name
  tibble::as_tibble(result)
}
