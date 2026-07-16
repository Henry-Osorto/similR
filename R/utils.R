`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L) y else x
}

is_blank_string <- function(x) {
  is.null(x) || length(x) == 0L || is.na(x[[1L]]) || !nzchar(trimws(x[[1L]]))
}

is_blank_vector <- function(x) {
  is.na(x) | !nzchar(trimws(as.character(x)))
}

safe_basename <- function(path) {
  if (is_blank_string(path)) return(NA_character_)
  basename(path)
}

format_bytes <- function(bytes) {
  if (is.null(bytes) || length(bytes) == 0L || is.na(bytes)) {
    return(NA_character_)
  }

  units <- c("B", "KB", "MB", "GB", "TB")
  index <- 1L
  value <- as.numeric(bytes)

  while (value >= 1024 && index < length(units)) {
    value <- value / 1024
    index <- index + 1L
  }

  sprintf("%.2f %s", value, units[[index]])
}

timestamp_tag <- function() {
  format(Sys.time(), "%Y%m%d%H%M%S", tz = "UTC")
}

utc_now <- function() {
  format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}

ensure_scalar_character <- function(x, arg) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x)) {
    rlang::abort(
      sprintf("`%s` debe ser una cadena de caracteres no vacía.", arg),
      class = "similR_invalid_argument"
    )
  }
  invisible(x)
}

ensure_data_frame <- function(x, arg = "data") {
  if (!inherits(x, "data.frame")) {
    rlang::abort(
      sprintf("`%s` debe ser un data.frame o tibble.", arg),
      class = "similR_invalid_argument"
    )
  }
  invisible(x)
}

safe_delete <- function(path) {
  existing <- path[file.exists(path) | dir.exists(path)]
  if (length(existing) > 0L) {
    files <- existing[file.exists(existing) & !dir.exists(existing)]
    if (length(files) > 0L) fs::file_delete(files)
    dirs <- existing[dir.exists(existing)]
    if (length(dirs) > 0L) fs::dir_delete(dirs)
  }
  invisible(existing)
}

rename_or_abort <- function(from, to) {
  ok <- file.rename(from, to)
  if (!isTRUE(ok)) {
    rlang::abort(
      sprintf("No fue posible mover `%s` a `%s`.", from, to),
      class = "similR_file_move_error"
    )
  }
  invisible(to)
}

atomic_write_json <- function(x, path, pretty = TRUE, auto_unbox = TRUE) {
  fs::dir_create(dirname(path), recurse = TRUE)
  temporary <- tempfile(
    pattern = paste0(".", basename(path), "-"),
    tmpdir = dirname(path),
    fileext = ".tmp"
  )
  backup <- paste0(path, ".bak-", timestamp_tag(), "-", Sys.getpid())

  on.exit({
    if (file.exists(temporary)) unlink(temporary, force = TRUE)
  }, add = TRUE)

  jsonlite::write_json(
    x,
    path = temporary,
    pretty = pretty,
    auto_unbox = auto_unbox,
    na = "null"
  )

  if (file.exists(path)) {
    rename_or_abort(path, backup)
  }

  success <- FALSE
  tryCatch(
    {
      rename_or_abort(temporary, path)
      success <- TRUE
    },
    error = function(e) {
      if (file.exists(backup) && !file.exists(path)) {
        file.rename(backup, path)
      }
      stop(e)
    }
  )

  if (success && file.exists(backup)) unlink(backup, force = TRUE)
  invisible(path)
}

parse_iso_datetime <- function(x) {
  if (is_blank_string(x)) return(as.POSIXct(NA))
  as.POSIXct(x, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")
}

longest_nonblank <- function(x, default = NA_character_) {
  x <- unique(trimws(as.character(x)))
  x <- x[!is.na(x) & nzchar(x)]
  if (length(x) == 0L) return(default)
  x[[which.max(nchar(x, type = "chars"))]]
}

first_nonblank <- function(x, default = NA_character_) {
  x <- as.character(x)
  index <- which(!is.na(x) & nzchar(trimws(x)))
  if (length(index) == 0L) return(default)
  trimws(x[[index[[1L]]]])
}

hash_text <- function(...) {
  values <- list(...)
  values <- lapply(values, function(x) {
    x <- as.character(x %||% "")
    x[is.na(x)] <- ""
    paste(x, collapse = "\u241e")
  })
  digest::digest(
    paste(unlist(values, use.names = FALSE), collapse = "\u241f"),
    algo = "sha256",
    serialize = FALSE
  )
}
