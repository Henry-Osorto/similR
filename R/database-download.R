#' Read and validate a manifest file
#' @noRd
read_manifest_file <- function(path) {
  if (!file.exists(path)) {
    rlang::abort(
      sprintf("No existe el manifest `%s`.", path),
      class = "similR_manifest_not_found"
    )
  }

  manifest <- tryCatch(
    jsonlite::read_json(path, simplifyVector = TRUE),
    error = function(e) {
      rlang::abort(
        c("No fue posible leer el manifest JSON.", "x" = conditionMessage(e)),
        class = "similR_invalid_manifest",
        parent = e
      )
    }
  )

  validate_manifest(manifest)
}

#' Read the locally installed manifest
#' @noRd
read_local_manifest <- function(strict = TRUE) {
  path <- local_manifest_path()
  if (!file.exists(path)) {
    if (isTRUE(strict)) {
      rlang::abort(
        "No existe un manifest local.",
        class = "similR_manifest_not_found"
      )
    }
    return(NULL)
  }

  tryCatch(
    read_manifest_file(path),
    error = function(e) {
      if (isTRUE(strict)) stop(e)
      NULL
    }
  )
}

#' Write the local manifest atomically
#' @noRd
write_local_manifest <- function(manifest) {
  manifest <- validate_manifest(manifest)
  atomic_write_json(manifest, local_manifest_path())
}

#' Download a complete release bundle to a staging directory
#' @noRd
download_release_bundle <- function(release, remote_manifest = NULL, quiet = FALSE) {
  config <- package_config()
  staging <- new_staging_dir()
  success <- FALSE

  on.exit({
    if (!success && dir.exists(staging)) fs::dir_delete(staging)
  }, add = TRUE)

  manifest_path <- fs::path(staging, config$manifest_asset)
  checksum_path <- fs::path(staging, config$checksum_asset)

  download_release_asset(
    release,
    config$manifest_asset,
    manifest_path,
    quiet = TRUE
  )
  downloaded_manifest <- read_manifest_file(manifest_path)

  if (!is.null(remote_manifest)) {
    remote_manifest <- validate_manifest(remote_manifest)
    stable_fields <- c(
      "data_version",
      "database_file",
      "database_schema_version",
      "sha256"
    )
    same_release <- all(vapply(
      stable_fields,
      function(field) identical(
        as.character(downloaded_manifest[[field]]),
        as.character(remote_manifest[[field]])
      ),
      logical(1)
    ))
    if (!same_release) {
      rlang::abort(
        "El manifest cambió entre la comprobación y la descarga.",
        class = "similR_release_changed"
      )
    }
  }

  manifest <- downloaded_manifest

  database_asset <- select_release_asset(
    release,
    name = manifest$database_file
  )
  if (!grepl(config$database_asset_pattern, database_asset$name[[1L]])) {
    rlang::abort(
      "El archivo indicado por el manifest no es una base permitida.",
      class = "similR_invalid_manifest"
    )
  }

  database_path <- fs::path(staging, manifest$database_file)

  download_release_asset(
    release,
    config$checksum_asset,
    checksum_path,
    quiet = TRUE
  )
  download_release_asset(
    release,
    manifest$database_file,
    database_path,
    quiet = quiet
  )

  checksums <- parse_checksums(checksum_path)
  checksum_from_file <- unname(checksums[[manifest$database_file]])
  if (is.null(checksum_from_file) || is.na(checksum_from_file)) {
    rlang::abort(
      "El archivo de checksums no contiene la base indicada en el manifest.",
      class = "similR_invalid_checksum_file"
    )
  }

  if (!identical(tolower(checksum_from_file), tolower(manifest$sha256))) {
    rlang::abort(
      "El checksum del manifest y el de checksums.txt no coinciden.",
      class = "similR_checksum_metadata_mismatch"
    )
  }

  verify_checksum(database_path, manifest$sha256)
  validation <- validate_database(database_path, manifest = manifest)

  success <- TRUE
  structure(
    list(
      staging_dir = staging,
      database_path = database_path,
      manifest_path = manifest_path,
      checksum_path = checksum_path,
      manifest = manifest,
      validation = validation,
      release = release
    ),
    class = "similR_release_bundle"
  )
}

#' Install a validated bundle without destroying the previous database
#' @noRd
install_release_bundle <- function(bundle, manifest_writer = write_local_manifest) {
  stopifnot(inherits(bundle, "similR_release_bundle"))

  manifest <- bundle$manifest
  target_database <- fs::path(user_data_dir(), manifest$database_file)
  old_manifest <- read_local_manifest(strict = FALSE)
  old_database <- if (!is.null(old_manifest)) {
    fs::path(user_data_dir(), basename(old_manifest$database_file))
  } else {
    NULL
  }

  target_backup <- NULL
  if (file.exists(target_database)) {
    target_backup <- paste0(target_database, ".bak-", timestamp_tag(), "-", Sys.getpid())
    rename_or_abort(target_database, target_backup)
  }

  installed <- FALSE
  tryCatch(
    {
      rename_or_abort(bundle$database_path, target_database)

      local_manifest <- manifest
      local_manifest$installed_at <- format(
        Sys.time(),
        "%Y-%m-%dT%H:%M:%SZ",
        tz = "UTC"
      )
      local_manifest$local_database_file <- basename(target_database)
      manifest_writer(local_manifest)
      installed <- TRUE
    },
    error = function(e) {
      if (file.exists(target_database)) unlink(target_database, force = TRUE)
      if (!is.null(target_backup) && file.exists(target_backup)) {
        file.rename(target_backup, target_database)
      }
      stop(e)
    }
  )

  if (installed && !is.null(target_backup) && file.exists(target_backup)) {
    unlink(target_backup, force = TRUE)
  }

  if (installed &&
      !is.null(old_database) &&
      !identical(fs::path_abs(old_database), fs::path_abs(target_database)) &&
      file.exists(old_database)) {
    tryCatch(
      unlink(old_database, force = TRUE),
      warning = function(w) NULL,
      error = function(e) {
        rlang::warn(
          paste("La base nueva se instaló, pero no se eliminó la anterior:", old_database),
          class = "similR_old_database_cleanup_warning"
        )
      }
    )
  }

  invisible(target_database)
}
