#' Information about the locally installed bibliographic database
#'
#' @return An object of class `similR_database_info`.
#' @export
#' @examples
#' \dontrun{
#' database_info()
#' }
database_info <- function() {
  manifest <- read_local_manifest(strict = FALSE)
  database_path <- local_database_path(must_exist = FALSE)
  installed <- !is.null(manifest) && file.exists(database_path)

  if (!installed) {
    return(structure(
      list(
        installed = FALSE,
        path = NA_character_,
        version = NA_character_,
        published_at = NA_character_,
        installed_at = NA_character_,
        number_of_articles = NA_real_,
        file_name = NA_character_,
        size_bytes = NA_real_,
        size = NA_character_,
        sha256 = NA_character_,
        embedding_model = NA_character_,
        embedding_status = NA_character_,
        embedding_dimensions = NA_integer_,
        embedding_normalized = NA,
        database_schema_version = NA_character_,
        minimum_package_version = NA_character_,
        compatible = NA
      ),
      class = "similR_database_info"
    ))
  }

  validation <- validate_database(database_path, manifest = manifest)
  size_bytes <- unname(file.info(database_path)$size)
  compatible <- utils::compareVersion(
    installed_package_version(),
    as.character(manifest$minimum_package_version)
  ) >= 0L

  structure(
    list(
      installed = TRUE,
      path = fs::path_abs(database_path),
      version = manifest$data_version,
      published_at = manifest$published_at,
      installed_at = manifest$installed_at %||% NA_character_,
      number_of_articles = validation$number_of_articles,
      file_name = basename(database_path),
      size_bytes = size_bytes,
      size = format_bytes(size_bytes),
      sha256 = manifest$sha256,
      embedding_model = manifest$embedding_model,
      embedding_status = manifest$embedding_status %||% NA_character_,
      embedding_dimensions = manifest$embedding_dimensions,
      embedding_normalized = manifest$embedding_normalized,
      database_schema_version = manifest$database_schema_version,
      minimum_package_version = manifest$minimum_package_version,
      compatible = compatible
    ),
    class = "similR_database_info"
  )
}

#' @export
print.similR_database_info <- function(x, ...) {
  if (!isTRUE(x$installed)) {
    cat("Base bibliográfica similR: no instalada\n")
    return(invisible(x))
  }

  cat("Base bibliográfica similR\n")
  cat("  Ruta:                 ", x$path, "\n", sep = "")
  cat("  Versión de datos:     ", x$version, "\n", sep = "")
  cat("  Fecha de publicación: ", x$published_at, "\n", sep = "")
  cat("  Artículos:            ", format(x$number_of_articles, big.mark = ","), "\n", sep = "")
  cat("  Tamaño:               ", x$size, "\n", sep = "")
  cat("  Modelo de embeddings: ", x$embedding_model, "\n", sep = "")
  cat("  Estado embeddings:    ", x$embedding_status, "\n", sep = "")
  cat("  Dimensiones:          ", x$embedding_dimensions, "\n", sep = "")
  cat("  Esquema:              ", x$database_schema_version, "\n", sep = "")
  cat("  Compatible:           ", if (isTRUE(x$compatible)) "sí" else "no", "\n", sep = "")
  invisible(x)
}

#' Remove locally managed bibliographic database files
#'
#' Removes only the local data files and manifest managed by `similR`. It does
#' not remove semantic models, package settings, or other cache content.
#'
#' @param force Logical. Skip the interactive confirmation.
#'
#' @return Invisibly, the paths that existed before removal.
#' @export
#' @examples
#' \dontrun{
#' remove_local_database()
#' }
remove_local_database <- function(force = FALSE) {
  if (!is.logical(force) || length(force) != 1L || is.na(force)) {
    rlang::abort("`force` debe ser TRUE o FALSE.")
  }

  paths <- unique(c(
    local_manifest_path(),
    local_database_files(),
    fs::dir_ls(
      user_data_dir(),
      regexp = "\\.staging-",
      type = "directory",
      fail = FALSE
    )
  ))
  existing <- paths[file.exists(paths) | dir.exists(paths)]

  if (length(existing) == 0L) {
    cli::cli_alert_info("No hay una base local que eliminar.")
    return(invisible(character()))
  }

  if (!isTRUE(force)) {
    if (!interactive()) {
      rlang::abort(
        "Use `remove_local_database(force = TRUE)` en una sesión no interactiva.",
        class = "similR_confirmation_required"
      )
    }

    answer <- readline(
      "Se eliminará la base bibliográfica local. Escriba 'ELIMINAR' para continuar: "
    )
    if (!identical(trimws(answer), "ELIMINAR")) {
      cli::cli_alert_info("Operación cancelada.")
      return(invisible(character()))
    }
  }

  safe_delete(existing)
  cli::cli_alert_success("La base bibliográfica local fue eliminada.")
  invisible(existing)
}
