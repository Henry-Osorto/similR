
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

normalize_lexical_text <- function(text) {
  normalized <- normalize_for_matching(text)
  normalized <- stringr::str_replace_all(normalized, "[–—−]", "-")
  stringr::str_squish(normalized)
}

tokenize_lexical_text <- function(text) {
  normalized <- normalize_lexical_text(text)
  if (!nzchar(normalized)) return(character())
  tokens <- stringr::str_extract_all(normalized, "[[:alnum:]][[:alnum:]_+.-]*")[[1L]]
  tokens <- tokens[nzchar(tokens)]
  keep_short <- tokens %in% technical_short_terms()
  tokens <- tokens[(nchar(tokens) > 1L | keep_short) & !tokens %in% lexical_stopwords()]
  tokens
}

exact_term_dictionary <- function() {
  unique(c(
    "structural equation model", "structural equations", "sem",
    "ordinary least squares", "ols", "logistic regression", "probit model",
    "negative binomial", "poisson regression", "panel data", "fixed effects",
    "random effects", "difference in differences", "did",
    "generalized method of moments", "gmm", "vector autoregression", "var",
    "vector error correction", "vecm", "autoregressive distributed lag", "ardl",
    "randomized controlled trial", "experimental design", "case study",
    "systematic review", "meta analysis", "bibliometric analysis", "survey data",
    "qualitative interviews", "machine learning", "natural language processing",
    "artificial intelligence", "inteligencia artificial",
    "scopus", "web of science", "dimensions", "openalex", "crossref",
    "world bank enterprise surveys", "enterprise surveys", "cepalstat",
    "world development indicators", "demographic and health survey",
    "latin america", "caribbean", "central america", "emerging markets",
    "developing countries", "low income countries", "middle income countries",
    "honduras", "guatemala", "el salvador", "nicaragua", "costa rica", "panama",
    "mexico", "colombia", "ecuador", "peru", "bolivia", "brazil", "argentina",
    "chile", "uruguay", "paraguay", "dominican republic", "united states",
    "canada", "spain", "university students", "estudiantes universitarios",
    "small and medium enterprises", "smes", "mipymes", "women", "mujeres",
    "patients", "pacientes", "firms", "empresas"
  ))
}

extract_doi_terms <- function(text) {
  normalized <- normalize_text(text, lowercase = TRUE)
  matches <- stringr::str_extract_all(
    normalized,
    "10\\.[0-9]{4,9}/[-._;()/:a-z0-9]+"
  )[[1L]]
  unique(stringr::str_remove(matches, "[.,;]+$"))
}

extract_exact_terms <- function(text) {
  normalized <- normalize_lexical_text(text)
  dictionary <- exact_term_dictionary()
  padded <- paste0(" ", normalized, " ")
  found <- dictionary[vapply(dictionary, function(term) {
    normalized_term <- normalize_lexical_text(term)
    stringr::str_detect(padded, stringr::fixed(paste0(" ", normalized_term, " ")))
  }, logical(1))]
  unique(c(found, extract_doi_terms(text)))
}

parse_json_tokens <- function(x) {
  if (is_blank_string(x)) return(character())
  value <- tryCatch(
    jsonlite::fromJSON(x, simplifyVector = TRUE),
    error = function(e) character()
  )
  as.character(value %||% character())
}

parse_semicolon_terms <- function(x) {
  if (is_blank_string(x)) return(character())
  values <- unlist(strsplit(as.character(x), ";", fixed = TRUE), use.names = FALSE)
  values <- trimws(values)
  unique(values[nzchar(values)])
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
      normalized_text = vapply(texts, normalize_lexical_text, character(1)),
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
