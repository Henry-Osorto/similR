resolve_release_paths <- function(release) {
  if (inherits(release, "similR_release")) {
    return(list(
      output_dir = release$output_dir,
      database_path = release$database_path,
      manifest_path = release$manifest_path,
      checksums_path = release$checksums_path
    ))
  }
  ensure_scalar_character(release, "release")
  directory <- fs::path_abs(release)
  if (!dir.exists(directory)) rlang::abort(sprintf("No existe `%s`.", directory))
  manifest_path <- fs::path(directory, package_config()$manifest_asset)
  checksums_path <- fs::path(directory, package_config()$checksum_asset)
  manifest <- read_manifest_file(manifest_path)
  list(
    output_dir = directory,
    database_path = fs::path(directory, manifest$database_file),
    manifest_path = manifest_path,
    checksums_path = checksums_path
  )
}

#' Validate a complete GitHub data release directory
#'
#' @param release A `similR_release` object or path to a release directory.
#'
#' @return A structured validation result.
#' @export
validate_release <- function(release) {
  paths <- resolve_release_paths(release)
  required <- unlist(paths[c("database_path", "manifest_path", "checksums_path")], use.names = FALSE)
  missing <- required[!file.exists(required)]
  if (length(missing) > 0L) {
    rlang::abort(paste("Faltan archivos de la Release:", paste(basename(missing), collapse = ", ")))
  }

  manifest <- read_manifest_file(paths$manifest_path)
  manifest <- validate_manifest(manifest)
  checksums <- parse_checksums(paths$checksums_path)
  expected <- checksums[[manifest$database_file]]
  if (is.null(expected)) {
    rlang::abort("checksums.txt no contiene la base declarada en el manifest.")
  }
  if (!identical(tolower(expected), tolower(manifest$sha256))) {
    rlang::abort("El hash del manifest no coincide con checksums.txt.")
  }
  verify_checksum(paths$database_path, expected)
  validation <- validate_database(paths$database_path, manifest)

  structure(
    list(
      valid = TRUE,
      output_dir = paths$output_dir,
      manifest = manifest,
      database = validation,
      checksum = expected
    ),
    class = "similR_release_validation"
  )
}
