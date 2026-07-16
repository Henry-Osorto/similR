read_previous_articles <- function(previous_database) {
  if (is.null(previous_database)) {
    return(tibble::tibble(article_id = character(), content_hash = character()))
  }
  if (inherits(previous_database, "data.frame")) {
    previous <- tibble::as_tibble(previous_database)
  } else {
    ensure_scalar_character(previous_database, "previous_database")
    if (!file.exists(previous_database)) {
      rlang::abort(sprintf("No existe `%s`.", previous_database))
    }
    connection <- open_database(previous_database, read_only = TRUE)
    on.exit(close_database(connection), add = TRUE)
    previous <- tibble::as_tibble(DBI::dbReadTable(connection, "articles"))
  }

  required <- c("article_id", "content_hash")
  missing <- setdiff(required, names(previous))
  if (length(missing) > 0L) {
    rlang::abort(paste("La base anterior no contiene:", paste(missing, collapse = ", ")))
  }
  previous
}

#' Compare a processed data set with a previous database
#'
#' @param new_data Newly processed article data.
#' @param previous_database Previous DuckDB path or compatible data frame.
#'
#' @return An object of class `similR_database_comparison` containing a row-level
#'   status table and summary counts.
#' @export
compare_database_versions <- function(new_data, previous_database) {
  ensure_data_frame(new_data, "new_data")
  required <- c("article_id", "content_hash")
  missing <- setdiff(required, names(new_data))
  if (length(missing) > 0L) {
    rlang::abort(paste("`new_data` no contiene:", paste(missing, collapse = ", ")))
  }

  previous <- read_previous_articles(previous_database)
  current_key <- tibble::as_tibble(new_data) |>
    dplyr::select(.data$article_id, current_hash = .data$content_hash)
  previous_key <- previous |>
    dplyr::select(.data$article_id, previous_hash = .data$content_hash)

  comparison <- dplyr::full_join(current_key, previous_key, by = "article_id") |>
    dplyr::mutate(
      status = dplyr::case_when(
        is.na(.data$previous_hash) ~ "new",
        is.na(.data$current_hash) ~ "removed",
        .data$current_hash == .data$previous_hash ~ "unchanged",
        TRUE ~ "modified"
      )
    ) |>
    dplyr::arrange(factor(.data$status, levels = c("new", "modified", "unchanged", "removed")), .data$article_id)

  counts <- comparison |>
    dplyr::count(.data$status, name = "n") |>
    tidyr::complete(status = c("new", "modified", "unchanged", "removed"), fill = list(n = 0L))
  summary <- stats::setNames(as.list(as.integer(counts$n)), counts$status)

  structure(
    list(table = comparison, summary = summary),
    class = "similR_database_comparison"
  )
}

#' @export
print.similR_database_comparison <- function(x, ...) {
  cat("Comparación de versiones de la base bibliográfica\n\n")
  cat(sprintf("Artículos nuevos:       %s\n", format(x$summary$new, big.mark = ",")))
  cat(sprintf("Artículos modificados:  %s\n", format(x$summary$modified, big.mark = ",")))
  cat(sprintf("Artículos sin cambios:  %s\n", format(x$summary$unchanged, big.mark = ",")))
  cat(sprintf("Artículos eliminados:   %s\n", format(x$summary$removed, big.mark = ",")))
  invisible(x)
}

merge_previous_timestamps <- function(data, previous_database, comparison) {
  if (is.null(previous_database)) return(data)
  if (is.character(previous_database) && !file.exists(previous_database)) return(data)
  previous <- read_previous_articles(previous_database)
  timestamp_fields <- intersect(c("article_id", "created_at", "updated_at"), names(previous))
  if (!all(c("article_id", "created_at", "updated_at") %in% timestamp_fields)) return(data)

  previous <- previous |>
    dplyr::select(.data$article_id, previous_created_at = .data$created_at, previous_updated_at = .data$updated_at)
  status <- comparison$table |>
    dplyr::select(.data$article_id, .data$status)

  data |>
    dplyr::left_join(previous, by = "article_id") |>
    dplyr::left_join(status, by = "article_id") |>
    dplyr::mutate(
      created_at = dplyr::coalesce(as.character(.data$previous_created_at), as.character(.data$created_at)),
      updated_at = dplyr::if_else(
        .data$status == "unchanged" & !is.na(.data$previous_updated_at),
        as.character(.data$previous_updated_at),
        utc_now()
      )
    ) |>
    dplyr::select(-.data$previous_created_at, -.data$previous_updated_at, -.data$status)
}
