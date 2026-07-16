#' Build a GitHub REST request
#' @noRd
github_request <- function(url, accept = "application/vnd.github+json") {
  config <- package_config()

  request <- httr2::request(url) |>
    httr2::req_headers(
      Accept = accept,
      `X-GitHub-Api-Version` = config$github_api_version,
      `User-Agent` = paste0(config$package_name, "/", installed_package_version())
    ) |>
    httr2::req_retry(
      max_tries = 3,
      retry_on_failure = TRUE
    )

  token <- Sys.getenv("GITHUB_PAT", unset = "")
  if (nzchar(token)) {
    request <- httr2::req_auth_bearer_token(request, token)
  }

  request
}

#' Convert one GitHub release payload into a stable record
#' @noRd
as_release_record <- function(x) {
  assets_raw <- x$assets %||% list()

  assets <- if (length(assets_raw) == 0L) {
    tibble::tibble(
      name = character(),
      browser_download_url = character(),
      api_url = character(),
      size = numeric(),
      digest = character(),
      content_type = character()
    )
  } else {
    tibble::tibble(
      name = vapply(assets_raw, function(a) a$name %||% NA_character_, character(1)),
      browser_download_url = vapply(
        assets_raw,
        function(a) a$browser_download_url %||% NA_character_,
        character(1)
      ),
      api_url = vapply(assets_raw, function(a) a$url %||% NA_character_, character(1)),
      size = vapply(assets_raw, function(a) as.numeric(a$size %||% NA_real_), numeric(1)),
      digest = vapply(assets_raw, function(a) a$digest %||% NA_character_, character(1)),
      content_type = vapply(
        assets_raw,
        function(a) a$content_type %||% NA_character_,
        character(1)
      )
    )
  }

  list(
    id = x$id %||% NA_real_,
    tag_name = x$tag_name %||% NA_character_,
    name = x$name %||% NA_character_,
    published_at = x$published_at %||% NA_character_,
    created_at = x$created_at %||% NA_character_,
    html_url = x$html_url %||% NA_character_,
    draft = isTRUE(x$draft),
    prerelease = isTRUE(x$prerelease),
    assets = assets
  )
}

#' Does a release contain a complete similR data bundle?
#' @noRd
is_data_release <- function(release, config = package_config()) {
  asset_names <- release$assets$name
  !isTRUE(release$draft) &&
    !isTRUE(release$prerelease) &&
    config$manifest_asset %in% asset_names &&
    config$checksum_asset %in% asset_names &&
    any(grepl(config$database_asset_pattern, asset_names))
}

#' Obtain the newest published release containing a complete data bundle
#' @noRd
github_latest_release <- function() {
  config <- validate_github_config()
  endpoint <- paste0(
    config$github_api_base,
    "/repos/",
    utils::URLencode(config$github_owner, reserved = TRUE),
    "/",
    utils::URLencode(config$github_repo, reserved = TRUE),
    "/releases?per_page=",
    config$release_scan_limit
  )

  response <- github_request(endpoint) |>
    httr2::req_perform()

  payload <- httr2::resp_body_json(response, simplifyVector = FALSE)
  releases <- lapply(payload, as_release_record)
  matches <- vapply(releases, is_data_release, logical(1), config = config)

  if (!any(matches)) {
    rlang::abort(
      c(
        "No se encontró una GitHub Release con una base completa.",
        "i" = paste0(
          "La Release debe incluir `", config$manifest_asset, "`, `",
          config$checksum_asset, "` y un archivo DuckDB válido."
        )
      ),
      class = "similR_release_not_found"
    )
  }

  releases[[which(matches)[[1L]]]]
}

#' Select one asset from a release
#' @noRd
select_release_asset <- function(release, name = NULL, pattern = NULL) {
  assets <- release$assets

  if (!is.null(name)) {
    selected <- assets[assets$name == name, , drop = FALSE]
  } else if (!is.null(pattern)) {
    selected <- assets[grepl(pattern, assets$name), , drop = FALSE]
  } else {
    rlang::abort("Debe proporcionar `name` o `pattern`.")
  }

  if (nrow(selected) != 1L) {
    rlang::abort(
      sprintf(
        "Se esperaba exactamente un recurso y se encontraron %s.",
        nrow(selected)
      ),
      class = "similR_release_asset_error"
    )
  }

  selected
}

#' Download one GitHub Release asset
#' @noRd
download_release_asset <- function(release, asset_name, destination, quiet = FALSE) {
  asset <- select_release_asset(release, name = asset_name)
  token <- Sys.getenv("GITHUB_PAT", unset = "")

  use_api_url <- nzchar(token) && !is.na(asset$api_url[[1L]])
  url <- if (use_api_url) asset$api_url[[1L]] else asset$browser_download_url[[1L]]
  accept <- "application/octet-stream"

  if (is.na(url) || !nzchar(url)) {
    rlang::abort(
      sprintf("El recurso `%s` no tiene una URL de descarga.", asset_name),
      class = "similR_release_asset_error"
    )
  }

  fs::dir_create(dirname(destination), recurse = TRUE)
  request <- github_request(url, accept = accept)
  if (!isTRUE(quiet)) request <- httr2::req_progress(request, type = "down")

  request |> httr2::req_perform(path = destination)

  if (!file.exists(destination) || file.info(destination)$size <= 0) {
    rlang::abort(
      sprintf("La descarga de `%s` no produjo un archivo válido.", asset_name),
      class = "similR_download_error"
    )
  }

  invisible(destination)
}

#' Download and parse the remote manifest
#' @noRd
download_remote_manifest <- function(release, quiet = TRUE) {
  path <- tempfile(fileext = ".json")
  on.exit(unlink(path, force = TRUE), add = TRUE)

  download_release_asset(
    release = release,
    asset_name = package_config()$manifest_asset,
    destination = path,
    quiet = quiet
  )

  read_manifest_file(path)
}
