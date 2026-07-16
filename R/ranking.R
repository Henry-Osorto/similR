
combine_dimension_scores <- function(scores, weights) {
  dimensions <- names(weights)[weights > 0]
  if (length(dimensions) == 0L) rlang::abort("No existen dimensiones ponderadas.")
  score_lengths <- vapply(scores[dimensions], length, integer(1))
  if (length(unique(score_lengths)) != 1L) {
    rlang::abort("Las puntuaciones tienen longitudes incompatibles.")
  }
  result <- rep(0, score_lengths[[1L]])
  for (dimension in dimensions) {
    current <- as.numeric(scores[[dimension]])
    current[!is.finite(current)] <- 0
    result <- result + weights[[dimension]] * current
  }
  pmin(1, pmax(0, result))
}

apply_article_filters <- function(articles, filters = list()) {
  if (is.null(filters)) filters <- list()
  if (!is.list(filters)) rlang::abort("`filters` debe ser una lista.")
  keep <- rep(TRUE, nrow(articles))

  if (!is.null(filters$year_min) && !is.na(filters$year_min[[1L]])) {
    year_min <- as.integer(filters$year_min[[1L]])
    keep <- keep & !is.na(articles$year) & articles$year >= year_min
  }
  if (!is.null(filters$year_max) && !is.na(filters$year_max[[1L]])) {
    year_max <- as.integer(filters$year_max[[1L]])
    keep <- keep & !is.na(articles$year) & articles$year <= year_max
  }
  if (!is.null(filters$years)) {
    keep <- keep & articles$year %in% as.integer(filters$years)
  }
  if (!is_blank_string(filters$source_title)) {
    pattern <- normalize_for_matching(filters$source_title[[1L]])
    keep <- keep & stringr::str_detect(
      normalize_for_matching(articles$source_title),
      stringr::fixed(pattern)
    )
  }
  if (!is_blank_string(filters$authors)) {
    pattern <- normalize_for_matching(filters$authors[[1L]])
    keep <- keep & stringr::str_detect(
      normalize_for_matching(articles$authors),
      stringr::fixed(pattern)
    )
  }
  if (!is_blank_string(filters$doi)) {
    doi <- normalize_doi(filters$doi[[1L]])
    keep <- keep & articles$doi_normalized == doi
  }
  if (!is.null(filters$article_id)) {
    keep <- keep & articles$article_id %in% as.character(filters$article_id)
  }
  keep[is.na(keep)] <- FALSE
  keep
}

similarity_label <- function(dimension) {
  labels <- c(
    theme = "temática",
    purpose = "de propósito",
    method = "metodológica",
    data = "de datos",
    context = "contextual"
  )
  unname(labels[[dimension]] %||% dimension)
}

explain_recommendation <- function(dimension_scores, article = NULL) {
  scores <- as.numeric(dimension_scores)
  names(scores) <- names(dimension_scores)
  scores <- scores[is.finite(scores) & !is.na(scores)]
  if (length(scores) == 0L) {
    return("La recomendación se obtuvo a partir del índice lexical disponible.")
  }
  ordered <- sort(scores, decreasing = TRUE)
  selected <- names(utils::head(ordered, min(3L, length(ordered))))
  labels <- vapply(selected, similarity_label, character(1))
  if (length(labels) == 1L) {
    paste0("Este artículo presenta su mayor coincidencia en la dimensión ", labels[[1L]], ".")
  } else if (length(labels) == 2L) {
    paste0(
      "Este artículo presenta sus mayores coincidencias en las dimensiones ",
      labels[[1L]], " y ", labels[[2L]], "."
    )
  } else {
    paste0(
      "Este artículo presenta sus mayores coincidencias en las dimensiones ",
      labels[[1L]], ", ", labels[[2L]], " y ", labels[[3L]], "."
    )
  }
}

rank_articles_lexical <- function(
    query,
    lexical_index,
    n = 20L,
    weights = NULL,
    filters = list()) {
  if (!inherits(lexical_index, "similR_lexical_index")) {
    rlang::abort("`lexical_index` no es un índice lexical válido.")
  }
  n <- as.integer(n)
  if (length(n) != 1L || is.na(n) || n < 1L) {
    rlang::abort("`n` debe ser un entero positivo.")
  }

  dimensions <- package_config()$dimensions
  available <- dimensions[nzchar(trimws(query[dimensions]))]
  effective_weights <- normalize_weights(weights, available)
  scores <- stats::setNames(vector("list", length(dimensions)), dimensions)
  components <- stats::setNames(vector("list", length(dimensions)), dimensions)
  number_articles <- nrow(lexical_index$articles)

  for (dimension in dimensions) {
    if (dimension %in% available) {
      current <- lexical_dimension_score(query[[dimension]], lexical_index$dimensions[[dimension]])
      scores[[dimension]] <- current$score
      components[[dimension]] <- current
    } else {
      scores[[dimension]] <- rep(NA_real_, number_articles)
      components[[dimension]] <- list(
        score = rep(NA_real_, number_articles),
        tfidf = rep(NA_real_, number_articles),
        bm25 = rep(NA_real_, number_articles),
        exact = rep(NA_real_, number_articles)
      )
    }
  }

  scores_for_index <- lapply(scores, function(x) {
    x[is.na(x)] <- 0
    x
  })
  global_score <- combine_dimension_scores(scores_for_index, effective_weights)
  articles <- lexical_index$articles
  keep <- apply_article_filters(articles, filters)

  result <- articles |>
    dplyr::mutate(
      index = 100 * global_score,
      similarity_theme = 100 * scores$theme,
      similarity_method = 100 * scores$method,
      similarity_data = 100 * scores$data,
      similarity_context = 100 * scores$context,
      similarity_purpose = 100 * scores$purpose,
      doi = ifelse(nzchar(.data$doi_normalized), .data$doi_normalized, .data$doi),
      engine = "lexical"
    ) |>
    dplyr::filter(.env$keep) |>
    dplyr::arrange(
      dplyr::desc(.data$index),
      dplyr::desc(dplyr::coalesce(.data$similarity_theme, -Inf)),
      dplyr::desc(.data$year),
      .data$title
    ) |>
    dplyr::slice_head(n = n)

  if (nrow(result) == 0L) {
    return(tibble::tibble(
      rank = integer(), index = numeric(), similarity_theme = numeric(),
      similarity_method = numeric(), similarity_data = numeric(),
      similarity_context = numeric(), similarity_purpose = numeric(),
      title = character(), authors = character(), year = integer(),
      doi = character(), keywords = character(), source_title = character(),
      abstract = character(), article_id = character(), explanation = character(),
      engine = character()
    ))
  }

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
  attr(result, "lexical_components") <- components
  tibble::as_tibble(result)
}
