.similr_package_name <- "similR"

#' Central package configuration
#'
#' @return A named list.
#' @noRd
package_config <- function() {
  list(
    package_name = getOption("similR.package_name", .similr_package_name),
    github_owner = getOption("similR.github_owner", "REPLACE_GITHUB_OWNER"),
    github_repo = getOption("similR.github_repo", "REPLACE_GITHUB_REPOSITORY"),
    github_api_base = getOption("similR.github_api_base", "https://api.github.com"),
    github_api_version = getOption("similR.github_api_version", "2022-11-28"),
    database_asset_pattern = getOption(
      "similR.database_asset_pattern",
      "^university_articles_[0-9]{4}-[0-9]{2}\\.duckdb$"
    ),
    manifest_asset = getOption("similR.manifest_asset", "manifest.json"),
    checksum_asset = getOption("similR.checksum_asset", "checksums.txt"),
    default_model = getOption(
      "similR.default_model",
      "intfloat/multilingual-e5-base"
    ),
    schema_version = getOption("similR.schema_version", "1.0"),
    minimum_package_version = getOption(
      "similR.minimum_package_version",
      "0.2.0"
    ),
    release_scan_limit = as.integer(getOption("similR.release_scan_limit", 30L)),
    dimensions = c("theme", "purpose", "method", "data", "context")
  )
}

#' Validate GitHub configuration
#' @noRd
validate_github_config <- function(config = package_config()) {
  placeholders <- c("REPLACE_GITHUB_OWNER", "REPLACE_GITHUB_REPOSITORY")
  invalid <- is.null(config$github_owner) || is.null(config$github_repo) ||
    !nzchar(config$github_owner) || !nzchar(config$github_repo) ||
    config$github_owner %in% placeholders || config$github_repo %in% placeholders

  if (invalid) {
    rlang::abort(
      c(
        "No se ha configurado el repositorio de datos de GitHub.",
        "i" = paste0(
          "Edite `package_config()` o defina las opciones ",
          "`similR.github_owner` y `similR.github_repo`."
        )
      ),
      class = "similR_github_not_configured"
    )
  }

  invisible(config)
}

#' Installed package version without failing in development mode
#' @noRd
installed_package_version <- function() {
  tryCatch(
    as.character(utils::packageVersion(.similr_package_name)),
    error = function(e) "0.2.0.9000"
  )
}
