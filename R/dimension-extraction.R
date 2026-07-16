dimension_patterns <- function() {
  list(
    purpose = paste0(
      "\\b(objetiv[oa]s?|prop[oó]sito|analiz(?:a|ar|amos)|evalu(?:a|ar)|",
      "examin(?:a|ar)|investig(?:a|ar)|determin(?:a|ar)|aims?|objectives?|",
      "purpose|examine|investigate|assess|evaluate|determine|analy[sz]e)\\b"
    ),
    method = paste0(
      "\\b(m[eé]todos?|metodolog[ií]a|modelo|regresi[oó]n|encuesta|entrevista|",
      "sem|panel|experimental|experimento|methodology|methods?|model|regression|",
      "survey|interview|structural equation|randomi[sz]ed|qualitative|quantitative)\\b"
    ),
    data = paste0(
      "\\b(datos?|muestra|base de datos|encuesta|observaciones|per[ií]odo|panel|",
      "dataset|sample|data|survey|observations|period|records?|respondents?)\\b"
    ),
    context = paste0(
      "\\b(pa[ií]s(?:es)?|regi[oó]n|ciudad|sector|universidad(?:es)?|empresa(?:s)?|",
      "estudiante(?:s)?|mujer(?:es)?|paciente(?:s)?|poblaci[oó]n|mercados? emergentes?|",
      "developing countr(?:y|ies)|emerging markets?|university students?|firms?|",
      "companies|patients?|women|population|latin america|caribbean|africa|asia|europe)\\b"
    )
  )
}

split_sentences <- function(text) {
  text <- normalize_text(text)
  if (!nzchar(text)) return(character())
  sentences <- stringi::stri_split_boundaries(text, type = "sentence")[[1L]]
  sentences <- normalize_text(sentences)
  sentences[nzchar(sentences)]
}

extract_sentences_by_pattern <- function(text, pattern, max_sentences = 3L) {
  sentences <- split_sentences(text)
  if (length(sentences) == 0L) return("")
  matches <- stringr::str_detect(stringi::stri_trans_tolower(sentences), pattern)
  selected <- sentences[matches]
  if (length(selected) == 0L) return("")
  paste(utils::head(selected, max_sentences), collapse = " ")
}

choose_dimension_text <- function(explicit, extracted, fallback, explicit_confidence = 1) {
  if (nzchar(normalize_text(explicit))) {
    return(list(text = normalize_text(explicit), source = "explicit", confidence = explicit_confidence))
  }
  if (nzchar(normalize_text(extracted))) {
    return(list(text = normalize_text(extracted), source = "rule_based", confidence = 0.75))
  }
  list(text = normalize_text(fallback), source = "fallback", confidence = 0.35)
}

recalculate_dimension_content_hash <- function(data) {
  data$content_hash <- vapply(seq_len(nrow(data)), function(i) {
    hash_text(
      data$title_normalized[[i]], data$authors[[i]], data$abstract[[i]],
      data$keywords[[i]], data$doi_normalized[[i]], data$year[[i]],
      data$source_title[[i]], data$theme_text[[i]], data$purpose_text[[i]],
      data$method_text[[i]], data$data_text[[i]], data$context_text[[i]]
    )
  }, character(1))
  data
}

#' Build texts for the five similarity dimensions
#'
#' Uses explicit fields when available, bilingual sentence rules second, and a
#' deterministic fallback based on title, keywords and abstract otherwise.
#'
#' @param data Output from [process_scopus()] or a compatible data frame.
#' @param language Language strategy. The first version uses multilingual rules
#'   for every option and records the selected value as metadata.
#'
#' @return A tibble with dimension texts, sources and confidence scores.
#' @export
build_dimension_texts <- function(
    data,
    language = c("auto", "es", "en", "multilingual")) {
  ensure_data_frame(data)
  language <- match.arg(language)
  required <- c(
    "article_id", "title", "title_normalized", "authors", "abstract",
    "keywords", "doi", "doi_normalized", "year", "source_title",
    "missing_abstract", "created_at", "updated_at"
  )
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    rlang::abort(paste("Faltan columnas requeridas:", paste(missing, collapse = ", ")))
  }

  for (field in c("theme", "purpose", "method", "data", "context")) {
    if (!field %in% names(data)) data[[field]] <- ""
  }

  if (nrow(data) == 0L) {
    for (dimension in package_config()$dimensions) {
      data[[paste0(dimension, "_text")]] <- character()
      data[[paste0(dimension, "_source")]] <- character()
      data[[paste0(dimension, "_confidence")]] <- numeric()
    }
    data$dimension_language <- character()
    class(data) <- unique(c("similR_dimension_articles", class(data)))
    return(data)
  }

  patterns <- dimension_patterns()
  rows <- lapply(seq_len(nrow(data)), function(i) {
    title <- normalize_text(data$title[[i]])
    keywords <- normalize_text(data$keywords[[i]])
    abstract <- normalize_text(data$abstract[[i]])
    thematic_fallback <- normalize_text(paste(title, keywords, abstract, sep = ". "))
    if (!nzchar(thematic_fallback)) thematic_fallback <- title

    theme <- if (nzchar(data$theme[[i]])) {
      list(text = normalize_text(data$theme[[i]]), source = "explicit", confidence = 1)
    } else {
      list(text = thematic_fallback, source = "constructed", confidence = 0.85)
    }

    purpose <- choose_dimension_text(
      data$purpose[[i]],
      extract_sentences_by_pattern(abstract, patterns$purpose),
      if (nzchar(abstract)) abstract else theme$text
    )
    method <- choose_dimension_text(
      data$method[[i]],
      extract_sentences_by_pattern(abstract, patterns$method),
      if (nzchar(abstract)) abstract else theme$text
    )
    data_dimension <- choose_dimension_text(
      data$data[[i]],
      extract_sentences_by_pattern(abstract, patterns$data),
      if (nzchar(abstract)) abstract else theme$text
    )
    context <- choose_dimension_text(
      data$context[[i]],
      extract_sentences_by_pattern(paste(title, abstract, keywords), patterns$context),
      if (nzchar(abstract)) paste(title, keywords, abstract) else theme$text
    )

    tibble::tibble(
      theme_text = theme$text,
      theme_source = theme$source,
      theme_confidence = as.numeric(theme$confidence),
      purpose_text = purpose$text,
      purpose_source = purpose$source,
      purpose_confidence = as.numeric(purpose$confidence),
      method_text = method$text,
      method_source = method$source,
      method_confidence = as.numeric(method$confidence),
      data_text = data_dimension$text,
      data_source = data_dimension$source,
      data_confidence = as.numeric(data_dimension$confidence),
      context_text = context$text,
      context_source = context$source,
      context_confidence = as.numeric(context$confidence)
    )
  })

  dimensions <- dplyr::bind_rows(rows)
  result <- dplyr::bind_cols(tibble::as_tibble(data), dimensions)
  result$dimension_language <- language
  result$updated_at <- utc_now()
  result <- recalculate_dimension_content_hash(result)
  class(result) <- unique(c("similR_dimension_articles", class(result)))
  result
}
