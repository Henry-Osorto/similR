#' Compare two data-version strings
#' @noRd
compare_data_versions <- function(installed, available) {
  if (is_blank_string(installed) && is_blank_string(available)) return(0L)
  if (is_blank_string(installed)) return(1L)
  if (is_blank_string(available)) return(-1L)
  utils::compareVersion(as.character(available), as.character(installed))
}

#' Check whether a newer bibliographic database is available
#'
#' The function consults GitHub Releases and compares the remote data manifest
#' with the locally installed manifest. Network failures are returned in the
#' `error` field and do not invalidate a working local database.
#'
#' @return A named list describing the installed and available versions.
#' @export
#' @examples
#' \dontrun{
#' check_database_update()
#' }
check_database_update <- function() {
  local_manifest <- read_local_manifest(strict = FALSE)
  installed <- !is.null(local_manifest) && file.exists(local_database_path())
  installed_version <- if (installed) local_manifest$data_version else NA_character_

  tryCatch(
    {
      release <- github_latest_release()
      remote_manifest <- download_remote_manifest(release, quiet = TRUE)
      comparison <- compare_data_versions(
        installed = installed_version,
        available = remote_manifest$data_version
      )

      list(
        installed = installed,
        installed_version = installed_version,
        available_version = remote_manifest$data_version,
        update_available = !installed || comparison > 0L,
        manifest = remote_manifest,
        release_tag = release$tag_name,
        release_published_at = release$published_at,
        error = NULL
      )
    },
    error = function(e) {
      list(
        installed = installed,
        installed_version = installed_version,
        available_version = NA_character_,
        update_available = FALSE,
        manifest = NULL,
        release_tag = NA_character_,
        release_published_at = NA_character_,
        error = conditionMessage(e)
      )
    }
  )
}

#' Download and install the latest bibliographic database
#'
#' Downloads the newest complete data release to a staging directory, verifies
#' SHA-256 integrity, validates the DuckDB schema, and only then switches the
#' local manifest to the new database. The previous database remains active if
#' any validation or installation step fails.
#'
#' @param force Logical. Reinstall even when the installed data version is
#'   current.
#' @param quiet Logical. Suppress informational messages and download progress.
#'
#' @return Invisibly, a list describing the update.
#' @export
#' @examples
#' \dontrun{
#' update_database()
#' }
update_database <- function(force = FALSE, quiet = FALSE) {
  if (!is.logical(force) || length(force) != 1L || is.na(force)) {
    rlang::abort("`force` debe ser TRUE o FALSE.")
  }
  if (!is.logical(quiet) || length(quiet) != 1L || is.na(quiet)) {
    rlang::abort("`quiet` debe ser TRUE o FALSE.")
  }

  release <- github_latest_release()
  remote_manifest <- download_remote_manifest(release, quiet = TRUE)
  local_manifest <- read_local_manifest(strict = FALSE)
  installed_version <- local_manifest$data_version %||% NA_character_
  comparison <- compare_data_versions(installed_version, remote_manifest$data_version)

  if (!isTRUE(force) && !is.null(local_manifest) && comparison <= 0L) {
    if (!isTRUE(quiet)) {
      cli::cli_alert_success(
        "La base local ya está actualizada ({remote_manifest$data_version})."
      )
    }
    return(invisible(list(
      updated = FALSE,
      installed_version = installed_version,
      available_version = remote_manifest$data_version,
      database_path = local_database_path(must_exist = TRUE)
    )))
  }

  if (!isTRUE(quiet)) {
    cli::cli_alert_info(
      "Descargando la base bibliográfica {remote_manifest$data_version}."
    )
  }

  bundle <- download_release_bundle(
    release = release,
    remote_manifest = remote_manifest,
    quiet = quiet
  )
  on.exit({
    if (dir.exists(bundle$staging_dir)) fs::dir_delete(bundle$staging_dir)
  }, add = TRUE)

  installed_path <- install_release_bundle(bundle)

  if (!isTRUE(quiet)) {
    cli::cli_alert_success(
      "Base {remote_manifest$data_version} instalada y verificada."
    )
  }

  invisible(list(
    updated = TRUE,
    previous_version = installed_version,
    installed_version = remote_manifest$data_version,
    database_path = installed_path,
    manifest = remote_manifest
  ))
}
