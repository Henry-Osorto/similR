#' User data directory
#' @noRd
user_data_dir <- function(create = TRUE) {
  configured <- getOption("similR.data_dir", NULL)
  path <- if (!is.null(configured)) {
    fs::path_abs(configured)
  } else {
    tools::R_user_dir(package_config()$package_name, which = "data")
  }

  if (isTRUE(create)) fs::dir_create(path, recurse = TRUE)
  path
}

#' User cache directory
#' @noRd
user_cache_dir <- function(create = TRUE) {
  configured <- getOption("similR.cache_dir", NULL)
  path <- if (!is.null(configured)) {
    fs::path_abs(configured)
  } else {
    tools::R_user_dir(package_config()$package_name, which = "cache")
  }

  if (isTRUE(create)) fs::dir_create(path, recurse = TRUE)
  path
}

#' Path to the installed local manifest
#' @noRd
local_manifest_path <- function() {
  fs::path(user_data_dir(), package_config()$manifest_asset)
}

#' Candidate local database files
#' @noRd
local_database_files <- function() {
  directory <- user_data_dir()
  if (!dir.exists(directory)) return(character())

  files <- fs::dir_ls(directory, type = "file", fail = FALSE)
  files[grepl(package_config()$database_asset_pattern, basename(files))]
}

#' Path to the active local database
#' @noRd
local_database_path <- function(must_exist = FALSE) {
  manifest <- read_local_manifest(strict = FALSE)
  candidate <- NULL

  if (!is.null(manifest) && !is_blank_string(manifest$database_file)) {
    candidate <- fs::path(user_data_dir(), basename(manifest$database_file))
  }

  if (is.null(candidate) || !file.exists(candidate)) {
    files <- local_database_files()
    if (length(files) > 0L) {
      info <- file.info(files)
      candidate <- files[order(info$mtime, decreasing = TRUE)][[1L]]
    }
  }

  if (isTRUE(must_exist) && (is.null(candidate) || !file.exists(candidate))) {
    rlang::abort(
      c(
        "No se encontró una base bibliográfica local.",
        "i" = "Ejecute `update_database()` para descargarla."
      ),
      class = "similR_database_not_found"
    )
  }

  candidate %||% fs::path(user_data_dir(), "database-not-installed.duckdb")
}

#' Temporary staging directory on the same volume as the data directory
#' @noRd
new_staging_dir <- function() {
  path <- fs::path(
    user_data_dir(),
    paste0(".staging-", timestamp_tag(), "-", Sys.getpid())
  )
  fs::dir_create(path, recurse = TRUE)
  path
}
