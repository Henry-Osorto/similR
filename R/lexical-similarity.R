
query_term_counts <- function(text, vocabulary) {
  tokens <- tokenize_lexical_text(text)
  if (length(tokens) == 0L || length(vocabulary) == 0L) {
    return(list(tokens = tokens, positions = integer(), counts = numeric()))
  }
  table_counts <- table(tokens)
  positions <- match(names(table_counts), vocabulary)
  keep <- !is.na(positions)
  list(
    tokens = tokens,
    positions = as.integer(positions[keep]),
    counts = as.numeric(table_counts[keep])
  )
}

rescale_nonnegative <- function(x) {
  x <- as.numeric(x)
  x[!is.finite(x) | x < 0] <- 0
  maximum <- max(x, na.rm = TRUE)
  if (!is.finite(maximum) || maximum <= 0) return(rep(0, length(x)))
  pmin(1, x / maximum)
}

#' Cosine similarity between two numeric vectors
#' @noRd
cosine_similarity <- function(x, y) {
  x <- as.numeric(x)
  y <- as.numeric(y)
  if (length(x) != length(y)) rlang::abort("Los vectores deben tener la misma longitud.")
  denominator <- sqrt(sum(x^2)) * sqrt(sum(y^2))
  if (!is.finite(denominator) || denominator == 0) return(0)
  sum(x * y) / denominator
}

#' TF-IDF cosine similarity for one dimension
#' @noRd
tfidf_similarity <- function(query_text, dimension_index) {
  number_documents <- length(dimension_index$article_id)
  terms <- query_term_counts(query_text, dimension_index$vocabulary)
  if (length(terms$positions) == 0L) return(rep(0, number_documents))

  query <- Matrix::sparseMatrix(
    i = rep.int(1L, length(terms$positions)),
    j = terms$positions,
    x = log1p(terms$counts),
    dims = c(1L, length(dimension_index$vocabulary))
  )
  query <- query %*% Matrix::Diagonal(x = dimension_index$tfidf_idf)
  query <- normalize_sparse_rows(query)
  scores <- as.numeric(dimension_index$tfidf %*% t(query))
  pmin(1, pmax(0, scores))
}

#' BM25 similarity for one dimension
#' @noRd
bm25_similarity <- function(
    query_text,
    dimension_index,
    k1 = 1.5,
    b = 0.75,
    k3 = 500) {
  number_documents <- length(dimension_index$article_id)
  terms <- query_term_counts(query_text, dimension_index$vocabulary)
  if (length(terms$positions) == 0L) return(rep(0, number_documents))

  average_length <- dimension_index$average_document_length
  if (!is.finite(average_length) || average_length <= 0) average_length <- 1
  length_factor <- 1 - b + b * dimension_index$document_length / average_length
  scores <- rep(0, number_documents)

  for (j in seq_along(terms$positions)) {
    position <- terms$positions[[j]]
    frequency <- as.numeric(dimension_index$counts[, position, drop = TRUE])
    query_frequency <- terms$counts[[j]]
    document_component <- frequency * (k1 + 1) / (frequency + k1 * length_factor)
    query_component <- query_frequency * (k3 + 1) / (query_frequency + k3)
    scores <- scores + dimension_index$bm25_idf[[position]] * document_component * query_component
  }

  rescale_nonnegative(scores)
}

exact_phrase_coverage <- function(query_terms, document_terms) {
  if (length(query_terms) == 0L) return(rep(0, length(document_terms)))
  vapply(document_terms, function(terms) {
    mean(query_terms %in% terms)
  }, numeric(1))
}

exact_token_coverage <- function(query_text, dimension_index) {
  terms <- query_term_counts(query_text, dimension_index$vocabulary)
  if (length(terms$positions) == 0L) return(rep(0, length(dimension_index$article_id)))
  presence <- dimension_index$counts[, unique(terms$positions), drop = FALSE] > 0
  as.numeric(Matrix::rowSums(presence)) / length(unique(terms$positions))
}

#' Exact-term and exact-token overlap score
#' @noRd
exact_match_score <- function(query_text, dimension_index) {
  query_terms <- extract_exact_terms(query_text)
  phrase_score <- exact_phrase_coverage(query_terms, dimension_index$exact_terms)
  token_score <- exact_token_coverage(query_text, dimension_index)
  if (length(query_terms) == 0L) {
    return(pmin(1, pmax(0, token_score)))
  }
  pmin(1, pmax(0, 0.60 * phrase_score + 0.40 * token_score))
}

lexical_dimension_score <- function(
    query_text,
    dimension_index,
    component_weights = c(tfidf = 0.45, bm25 = 0.35, exact = 0.20)) {
  component_weights <- component_weights / sum(component_weights)
  tfidf <- tfidf_similarity(query_text, dimension_index)
  bm25 <- bm25_similarity(query_text, dimension_index)
  exact <- exact_match_score(query_text, dimension_index)
  score <- component_weights[["tfidf"]] * tfidf +
    component_weights[["bm25"]] * bm25 +
    component_weights[["exact"]] * exact
  list(
    score = pmin(1, pmax(0, score)),
    tfidf = tfidf,
    bm25 = bm25,
    exact = exact
  )
}
