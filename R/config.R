.similr_package_name <- "similR"

#' Central package configuration
#'
#' @return A named list.
#' @noRd
package_config <- function() {
  list(
    package_name = getOption("similR.package_name", .similr_package_name),
    github_owner = getOption("similR.github_owner", "Henry-Osorto"),
    github_repo = getOption("similR.github_repo", "similR"),
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
      "0.4.0"
    ),
    lexical_index_version = getOption("similR.lexical_index_version", "1.0"),
    semantic_index_version = getOption("similR.semantic_index_version", "1.0"),
    query_prefix = getOption("similR.query_prefix", "query: "),
    passage_prefix = getOption("similR.passage_prefix", "passage: "),
    python_version = getOption("similR.python_version", ">=3.10"),
    python_packages = getOption(
      "similR.python_packages",
      c("sentence-transformers>=3.0", "numpy>=1.24")
    ),
    release_scan_limit = as.integer(getOption("similR.release_scan_limit", 30L)),
    dimensions = c("theme", "purpose", "method", "data", "context")
  )
}

#' Validate GitHub configuration
#' @noRd
validate_github_config <- function(config = package_config()) {
  placeholders <- c("Henry-Osorto", "similR")
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
    error = function(e) "0.4.0.9003"
  )
}
