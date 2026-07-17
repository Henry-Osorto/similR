bibliographic_aliases <- function() {
  list(
    title = c("title", "document_title", "article_title", "titulo", "titulo_del_documento"),
    authors = c("authors", "author_names", "author_full_names", "autores", "autor_es"),
    abstract = c("abstract", "summary", "resumen", "descripcion", "description"),
    author_keywords = c("author_keywords", "keywords", "palabras_clave", "author_keyword"),
    index_keywords = c("index_keywords", "indexed_keywords", "index_terms", "keywords_plus"),
    doi = c("doi", "digital_object_identifier", "document_doi"),
    year = c("year", "publication_year", "ano", "anio", "py"),
    source_title = c("source_title", "journal", "journal_title", "publication_name", "revista", "so"),
    theme = c("theme", "topic", "tema", "thematic_description"),
    purpose = c("purpose", "objective", "aim", "objetivo", "proposito"),
    method = c("method", "methods", "methodology", "metodo", "metodologia"),
    data = c("data", "dataset", "data_source", "datos", "fuente_de_datos"),
    context = c("context", "population", "setting", "contexto", "poblacion", "ubicacion")
  )
}

normalize_text <- function(x, lowercase = FALSE, remove_diacritics = FALSE) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x <- stringi::stri_trans_nfkc(x)
  x <- stringr::str_replace_all(x, "[\\u0000-\\u001F\\u007F]", " ")
  x <- stringr::str_squish(x)
  if (isTRUE(lowercase)) x <- stringi::stri_trans_tolower(x)
  if (isTRUE(remove_diacritics)) x <- stringi::stri_trans_general(x, "Latin-ASCII")
  x
}

normalize_for_matching <- function(x) {
  x <- normalize_text(x, lowercase = TRUE, remove_diacritics = TRUE)
  x <- stringr::str_replace_all(x, "[^[:alnum:]]+", " ")
  stringr::str_squish(x)
}

normalize_doi <- function(x) {
  x <- normalize_text(x, lowercase = TRUE)
  x <- stringr::str_replace(x, "^https?://(dx\\.)?doi\\.org/", "")
  x <- stringr::str_replace(x, "^doi\\s*:\\s*", "")
  x <- stringr::str_replace_all(x, "\\s+", "")
  x <- stringr::str_replace(x, "[.,;]+$", "")
  x[!stringr::str_detect(x, "^10\\.[0-9]{4,9}/\\S+$")] <- ""
  x
}

clean_authors <- function(x) {
  x <- normalize_text(x)
  x <- stringr::str_replace_all(x, "\\s*\\|\\s*", "; ")
  x <- stringr::str_replace_all(x, "\\s*;\\s*", "; ")
  x <- stringr::str_replace_all(x, ";{2,}", ";")
  stringr::str_remove(x, ";$")
}

normalize_authors_for_id <- function(x) {
  x <- normalize_for_matching(x)
  stringr::str_replace_all(x, "\\s+", "_")
}

clean_keywords <- function(...) {
  values <- list(...)
  values <- lapply(values, function(x) {
    x <- normalize_text(x)
    x <- stringr::str_replace_all(x, "\\s*[,|]\\s*", "; ")
    x
  })

  purrr::pmap_chr(values, function(...) {
    current <- c(...)
    tokens <- unlist(stringr::str_split(current, "\\s*;\\s*"), use.names = FALSE)
    tokens <- normalize_text(tokens)
    tokens <- tokens[nzchar(tokens)]
    tokens <- tokens[!duplicated(normalize_for_matching(tokens))]
    paste(tokens, collapse = "; ")
  })
}

resolve_column_map <- function(data, column_map = NULL, source = "auto") {
  cleaned_names <- janitor::make_clean_names(names(data))
  names(data) <- cleaned_names
  aliases <- bibliographic_aliases()

  resolved <- stats::setNames(rep(NA_character_, length(aliases)), names(aliases))

  if (!is.null(column_map)) {
    if (is.null(names(column_map)) || any(!nzchar(names(column_map)))) {
      rlang::abort("`column_map` debe ser un vector nombrado.")
    }
    unknown <- setdiff(names(column_map), names(aliases))
    if (length(unknown) > 0L) {
      rlang::abort(paste("Campos canónicos desconocidos:", paste(unknown, collapse = ", ")))
    }
    mapped <- janitor::make_clean_names(unname(column_map))
    missing <- setdiff(mapped, cleaned_names)
    if (length(missing) > 0L) {
      rlang::abort(paste("Columnas no encontradas:", paste(missing, collapse = ", ")))
    }
    resolved[names(column_map)] <- mapped
  }

  for (canonical in names(aliases)) {
    if (!is.na(resolved[[canonical]])) next
    candidates <- janitor::make_clean_names(aliases[[canonical]])
    found <- intersect(candidates, cleaned_names)
    if (length(found) > 0L) resolved[[canonical]] <- found[[1L]]
  }

  if (is.na(resolved[["title"]])) {
    rlang::abort(
      c(
        "No fue posible identificar la columna de título.",
        "i" = "Proporcione `column_map = c(title = \"nombre_columna\", ...)`."
      ),
      class = "similR_missing_title_column"
    )
  }

  list(data = data, map = resolved, source = source)
}

pull_mapped_column <- function(
    data,
    map,
    name,
    default = NA_character_) {
  
  if (!inherits(data, "data.frame")) {
    rlang::abort(
      "El objeto interno `data` debe ser un data.frame o tibble.",
      class = "similR_invalid_internal_data"
    )
  }
  
  number_rows <- base::NROW(data)
  
  if (
    length(number_rows) != 1L ||
    is.na(number_rows) ||
    number_rows < 0L
  ) {
    rlang::abort(
      "No fue posible determinar el número de registros bibliográficos.",
      class = "similR_invalid_row_count"
    )
  }
  
  column <- unname(map[name])
  
  column_missing <-
    length(column) != 1L ||
    is.na(column) ||
    !nzchar(column) ||
    !(column %in% names(data))
  
  if (column_missing) {
    return(rep_len(default, number_rows))
  }
  
  value <- data[[column]]
  
  if (length(value) != number_rows) {
    rlang::abort(
      sprintf(
        "La columna `%s` tiene %s valores, pero se esperaban %s.",
        column,
        length(value),
        number_rows
      ),
      class = "similR_invalid_mapped_column"
    )
  }
  
  value
}

canonicalize_bibliographic_data <- function(data, map) {
  author_keywords <- pull_mapped_column(data, map, "author_keywords", "")
  index_keywords <- pull_mapped_column(data, map, "index_keywords", "")

  result <- tibble::tibble(
    title = normalize_text(pull_mapped_column(data, map, "title", "")),
    authors = clean_authors(pull_mapped_column(data, map, "authors", "")),
    abstract = normalize_text(pull_mapped_column(data, map, "abstract", "")),
    keywords = clean_keywords(author_keywords, index_keywords),
    doi = normalize_text(pull_mapped_column(data, map, "doi", "")),
    year = suppressWarnings(as.integer(as.character(pull_mapped_column(data, map, "year", NA_integer_)))),
    source_title = normalize_text(pull_mapped_column(data, map, "source_title", "")),
    theme = normalize_text(pull_mapped_column(data, map, "theme", "")),
    purpose = normalize_text(pull_mapped_column(data, map, "purpose", "")),
    method = normalize_text(pull_mapped_column(data, map, "method", "")),
    data = normalize_text(pull_mapped_column(data, map, "data", "")),
    context = normalize_text(pull_mapped_column(data, map, "context", ""))
  )

  result$doi_normalized <- normalize_doi(result$doi)
  result$title_normalized <- normalize_for_matching(result$title)
  result$authors_normalized <- normalize_authors_for_id(result$authors)
  result
}

row_completeness <- function(data) {
  fields <- intersect(
    c("title", "authors", "abstract", "keywords", "doi_normalized", "source_title", "theme", "purpose", "method", "data", "context"),
    names(data)
  )
  if (length(fields) == 0L) return(rep(0, nrow(data)))
  rowSums(vapply(data[fields], function(x) !is_blank_vector(x), logical(nrow(data))))
}

merge_keyword_values <- function(x) {
  tokens <- unlist(stringr::str_split(as.character(x), "\\s*;\\s*"), use.names = FALSE)
  tokens <- normalize_text(tokens)
  tokens <- tokens[nzchar(tokens)]
  tokens <- tokens[!duplicated(normalize_for_matching(tokens))]
  paste(tokens, collapse = "; ")
}

merge_duplicate_group <- function(group) {
  score <- row_completeness(group)
  abstract_length <- nchar(group$abstract, type = "chars")
  best <- order(score, abstract_length, decreasing = TRUE, na.last = TRUE)[[1L]]
  out <- group[best, , drop = FALSE]

  out$title <- longest_nonblank(group$title, "")
  out$authors <- merge_keyword_values(group$authors)
  out$abstract <- longest_nonblank(group$abstract, "")
  out$keywords <- merge_keyword_values(group$keywords)
  out$doi <- first_nonblank(group$doi, "")
  out$doi_normalized <- first_nonblank(group$doi_normalized, "")
  out$year <- {
    years <- group$year[!is.na(group$year)]
    if (length(years) == 0L) NA_integer_ else as.integer(years[[1L]])
  }
  out$source_title <- first_nonblank(group$source_title, "")
  for (field in c("theme", "purpose", "method", "data", "context")) {
    out[[field]] <- longest_nonblank(group[[field]], "")
  }
  out$title_normalized <- normalize_for_matching(out$title)
  out$authors_normalized <- normalize_authors_for_id(out$authors)
  out
}

collapse_by_key <- function(data, key, rule) {
  valid <- !is_blank_vector(key)
  grouping <- ifelse(valid, paste0(rule, ":", key), paste0("row:", seq_len(nrow(data))))
  groups <- split(seq_len(nrow(data)), grouping)
  merged <- lapply(groups, function(index) merge_duplicate_group(data[index, , drop = FALSE]))
  result <- dplyr::bind_rows(merged)
  report <- tibble::tibble(
    rule = rule,
    key = names(groups),
    original_rows = lengths(groups),
    removed_rows = pmax(lengths(groups) - 1L, 0L)
  ) |>
    dplyr::filter(.data$removed_rows > 0L)
  list(data = result, report = report)
}

find_possible_duplicates <- function(data, threshold = 0.08, max_records = 5000L) {
  if (nrow(data) < 2L || nrow(data) > max_records) {
    return(tibble::tibble(
      article_a = character(), article_b = character(), year = integer(),
      title_a = character(), title_b = character(), normalized_distance = numeric()
    ))
  }

  candidate_groups <- split(seq_len(nrow(data)), ifelse(is.na(data$year), "NA", data$year))
  output <- list()
  counter <- 0L

  for (indices in candidate_groups) {
    if (length(indices) < 2L) next
    combinations <- utils::combn(indices, 2L)
    for (column in seq_len(ncol(combinations))) {
      i <- combinations[1L, column]
      j <- combinations[2L, column]
      a <- data$title_normalized[[i]]
      b <- data$title_normalized[[j]]
      if (!nzchar(a) || !nzchar(b) || identical(a, b)) next
      distance <- as.numeric(utils::adist(a, b)) / max(nchar(a), nchar(b), 1L)
      if (distance <= threshold) {
        counter <- counter + 1L
        output[[counter]] <- tibble::tibble(
          article_a = data$article_id[[i]],
          article_b = data$article_id[[j]],
          year = data$year[[i]],
          title_a = data$title[[i]],
          title_b = data$title[[j]],
          normalized_distance = distance
        )
      }
    }
  }

  if (length(output) == 0L) {
    return(tibble::tibble(
      article_a = character(), article_b = character(), year = integer(),
      title_a = character(), title_b = character(), normalized_distance = numeric()
    ))
  }
  dplyr::bind_rows(output)
}

assign_article_identifiers <- function(data) {
  data$article_id <- vapply(seq_len(nrow(data)), function(i) {
    if (nzchar(data$doi_normalized[[i]])) {
      return(hash_text("doi", data$doi_normalized[[i]]))
    }
    hash_text(
      "record",
      data$title_normalized[[i]],
      data$year[[i]] %||% "",
      data$authors_normalized[[i]]
    )
  }, character(1))

  data$content_hash <- vapply(seq_len(nrow(data)), function(i) {
    hash_text(
      data$title_normalized[[i]], data$authors[[i]], data$abstract[[i]],
      data$keywords[[i]], data$doi_normalized[[i]], data$year[[i]],
      data$source_title[[i]], data$theme[[i]], data$purpose[[i]],
      data$method[[i]], data$data[[i]], data$context[[i]]
    )
  }, character(1))
  data
}

#' Process Scopus or generic institutional bibliographic data
#'
#' @param data A data frame containing bibliographic records.
#' @param column_map Optional named vector mapping canonical fields to source columns.
#' @param source Source format: `"auto"`, `"scopus"`, or `"generic"`.
#' @param remove_duplicates Whether exact duplicate groups should be collapsed.
#'
#' @return A processed tibble. Duplicate diagnostics are stored in attributes
#'   `duplicate_report` and `possible_duplicates`.
#' @export
process_scopus <- function(
    data,
    column_map = NULL,
    source = c("auto", "scopus", "generic"),
    remove_duplicates = TRUE) {
  ensure_data_frame(data)
  source <- match.arg(source)
  if (!is.logical(remove_duplicates) || length(remove_duplicates) != 1L || is.na(remove_duplicates)) {
    rlang::abort("`remove_duplicates` debe ser TRUE o FALSE.")
  }

  resolved <- resolve_column_map(tibble::as_tibble(data), column_map, source)
  result <- canonicalize_bibliographic_data(resolved$data, resolved$map)
  result <- result[nzchar(result$title_normalized), , drop = FALSE]

  reports <- list()
  if (isTRUE(remove_duplicates) && nrow(result) > 0L) {
    doi_stage <- collapse_by_key(result, result$doi_normalized, "doi")
    result <- doi_stage$data
    reports[["doi"]] <- doi_stage$report

    title_year_key <- ifelse(
      nzchar(result$title_normalized) & !is.na(result$year),
      paste(result$title_normalized, result$year, sep = "|"),
      ""
    )
    title_year_stage <- collapse_by_key(result, title_year_key, "title_year")
    result <- title_year_stage$data
    reports[["title_year"]] <- title_year_stage$report

    title_author_key <- ifelse(
      nzchar(result$title_normalized) & nzchar(result$authors_normalized),
      paste(result$title_normalized, result$authors_normalized, sep = "|"),
      ""
    )
    title_author_stage <- collapse_by_key(result, title_author_key, "title_authors")
    result <- title_author_stage$data
    reports[["title_authors"]] <- title_author_stage$report
  }

  result <- assign_article_identifiers(result)
  if (isTRUE(remove_duplicates) && anyDuplicated(result$article_id)) {
    id_stage <- collapse_by_key(result, result$article_id, "stable_id")
    result <- assign_article_identifiers(id_stage$data)
    reports[["stable_id"]] <- id_stage$report
  }
  now <- utc_now()
  result$missing_abstract <- !nzchar(result$abstract)
  result$created_at <- now
  result$updated_at <- now

  result <- result |>
    dplyr::select(
      .data$article_id, .data$title, .data$title_normalized,
      .data$authors, .data$authors_normalized, .data$abstract,
      .data$keywords, .data$doi, .data$doi_normalized, .data$year,
      .data$source_title, .data$theme, .data$purpose, .data$method,
      .data$data, .data$context, .data$missing_abstract,
      .data$content_hash, .data$created_at, .data$updated_at
    ) |>
    dplyr::arrange(.data$title_normalized, .data$year)

  duplicate_report <- dplyr::bind_rows(reports)
  possible_duplicates <- find_possible_duplicates(result)
  attr(result, "duplicate_report") <- duplicate_report
  attr(result, "possible_duplicates") <- possible_duplicates
  attr(result, "source_format") <- source
  class(result) <- unique(c("similR_articles", class(result)))
  result
}
