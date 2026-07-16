lexical_stopwords <- function() {
  unique(c(
    "a", "al", "algo", "ante", "bajo", "con", "contra", "como", "de", "del",
    "desde", "donde", "durante", "e", "el", "ella", "ellos", "en", "entre",
    "era", "es", "esa", "ese", "esta", "este", "fue", "ha", "hacia", "hasta",
    "la", "las", "lo", "los", "más", "muy", "no", "o", "para", "pero", "por",
    "que", "se", "sin", "sobre", "su", "sus", "también", "un", "una", "y",
    "an", "and", "are", "as", "at", "be", "been", "between", "by", "for",
    "from", "has", "have", "in", "into", "is", "it", "its", "of", "on", "or",
    "our", "that", "the", "their", "these", "this", "to", "using", "was", "were",
    "with", "without"
  ))
}

technical_short_terms <- function() {
  c("r", "ai", "ia", "sem", "ols", "var", "vecm", "did", "gmm", "ml", "nlp")
}

tokenize_lexical_text <- function(text) {
  normalized <- normalize_for_matching(text)
  tokens <- stringr::str_extract_all(normalized, "[[:alnum:]][[:alnum:]_+.-]*")[[1L]]
  tokens <- tokens[nzchar(tokens)]
  keep_short <- tokens %in% technical_short_terms()
  tokens <- tokens[(nchar(tokens) > 1L | keep_short) & !tokens %in% lexical_stopwords()]
  tokens
}

exact_term_dictionary <- function() {
  c(
    "structural equation model", "sem", "ordinary least squares", "ols",
    "vector autoregression", "var", "vector error correction", "vecm",
    "difference in differences", "did", "generalized method of moments", "gmm",
    "scopus", "web of science", "world bank enterprise surveys", "enterprise surveys",
    "latin america", "caribbean", "emerging markets", "developing countries",
    "honduras", "guatemala", "el salvador", "nicaragua", "costa rica", "panama",
    "mexico", "colombia", "ecuador", "peru", "brazil", "argentina", "chile"
  )
}

extract_exact_terms <- function(text) {
  normalized <- normalize_for_matching(text)
  dictionary <- exact_term_dictionary()
  found <- dictionary[vapply(dictionary, function(term) {
    stringr::str_detect(normalized, stringr::fixed(normalize_for_matching(term)))
  }, logical(1))]
  unique(found)
}

build_lexical_documents <- function(data) {
  dimensions <- package_config()$dimensions
  required <- paste0(dimensions, "_text")
  missing <- setdiff(c("article_id", "content_hash", required), names(data))
  if (length(missing) > 0L) {
    rlang::abort(paste("Faltan columnas para el corpus lexical:", paste(missing, collapse = ", ")))
  }

  output <- lapply(dimensions, function(dimension) {
    texts <- data[[paste0(dimension, "_text")]]
    tokens <- lapply(texts, tokenize_lexical_text)
    tibble::tibble(
      article_id = data$article_id,
      dimension = dimension,
      normalized_text = vapply(tokens, paste, collapse = " ", character(1)),
      tokens_json = vapply(tokens, function(x) {
        as.character(jsonlite::toJSON(x, auto_unbox = FALSE))
      }, character(1)),
      document_length = as.integer(lengths(tokens)),
      exact_terms = vapply(texts, function(x) {
        paste(extract_exact_terms(x), collapse = "; ")
      }, character(1)),
      content_hash = data$content_hash
    )
  })

  dplyr::bind_rows(output)
}
