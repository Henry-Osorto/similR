# UniLitR — Fase 1: código completo

Este documento consolida el contenido definitivo de todos los archivos generados en la Fase 1.

## `.Rbuildignore`

```text
^UniLitR\.Rproj$
^\.Rproj\.user$
^\.github$
^data-raw$
^release$
^PHASE1_CODEBOOK\.md$
^PHASE1_ARCHITECTURE\.md$
^LICENSE\.md$
```

## `.gitignore`

```text
.Rproj.user
.Rhistory
.RData
.Ruserdata
.Renviron
release/
data-raw/input/*
!data-raw/input/.gitkeep
```

## `DESCRIPTION`

```text
Package: UniLitR
Type: Package
Title: Local Recommendation of Institutional Scientific Literature
Version: 0.1.0.9000
Authors@R: 
    person(
      given = "Henry",
      family = "Osorto",
      email = "REPLACE_WITH_VALID_EMAIL@example.org",
      role = c("aut", "cre")
    )
Description: Provides infrastructure for a local Shiny application that
    downloads, validates, versions, and reads an institutional scientific
    literature database distributed through GitHub Releases. The package is
    designed to support lexical and semantic article recommendation engines
    in later development phases while keeping the database and package code
    independently versioned.
License: MIT + file LICENSE
URL: https://github.com/REPLACE_GITHUB_OWNER/REPLACE_GITHUB_REPOSITORY
BugReports: https://github.com/REPLACE_GITHUB_OWNER/REPLACE_GITHUB_REPOSITORY/issues
Encoding: UTF-8
Roxygen: list(markdown = TRUE)
RoxygenNote: 7.3.2
Depends:
    R (>= 4.2.0)
Imports:
    bslib,
    cli,
    DBI,
    digest,
    duckdb,
    fs,
    httr2,
    jsonlite,
    rlang,
    shiny,
    tibble
Suggests:
    testthat (>= 3.2.0),
    withr
Config/testthat/edition: 3
```

## `LICENSE`

```text
YEAR: 2026
COPYRIGHT HOLDER: Henry Osorto
```

## `LICENSE.md`

```markdown
# MIT License

Copyright (c) 2026 Henry Osorto

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## `NAMESPACE`

```text
# Generated manually for Phase 1. Run devtools::document() after editing roxygen comments.
S3method(print,UniLitR_database_info)
export(check_database_update)
export(database_info)
export(remove_local_database)
export(run_app)
export(update_database)
```

## `NEWS.md`

```markdown
# UniLitR 0.1.0.9000

## Phase 1

- Added central package and GitHub configuration.
- Added user-specific data and cache paths.
- Added GitHub Release discovery for complete data bundles.
- Added SHA-256 verification and manifest validation.
- Added DuckDB schema validation.
- Added atomic database installation and rollback behavior.
- Added database update, information, removal, and Shiny startup functions.
- Added a minimal local Shiny status application.
- Added offline unit tests using mocks rather than live GitHub requests.
```

## `PHASE1_ARCHITECTURE.md`

```markdown
# Fase 1 — decisiones arquitectónicas

## Alcance

Esta fase implementa el ciclo de vida seguro de una base bibliográfica DuckDB
separada del paquete. El ranking lexical, embeddings y aplicación completa se
incorporan en fases posteriores sin cambiar los contratos de rutas, manifest o
GitHub Releases.

## Decisiones

1. **Datos separados del paquete.** GitHub Releases contiene la base, manifest y
   checksum; el repositorio principal contiene código.
2. **Release de datos detectable.** Se examinan releases recientes y se toma la
   primera release publicada, no preliminar y no borrador que contenga los tres
   recursos obligatorios.
3. **Descarga atómica.** La base se descarga a una carpeta de staging ubicada en
   el mismo volumen que el directorio final.
4. **Verificación doble.** El hash del manifest debe coincidir con
   `checksums.txt`, y ambos deben coincidir con el archivo descargado.
5. **Validación estructural.** DuckDB debe abrir en modo de solo lectura y
   contener las tablas y columnas contractuales.
6. **Activación por manifest.** La base nueva solo se vuelve activa después de
   escribir correctamente el manifest local.
7. **Rollback.** Si falla la activación, se restaura una base anterior con el
   mismo nombre y el manifest anterior permanece vigente.
8. **Sin efectos en `.onLoad()`.** Cargar el paquete no accede a internet, no
   inicializa Python y no escribe archivos.
9. **Rutas configurables.** En producción se usa `tools::R_user_dir()`; en tests
   se pueden aislar rutas mediante opciones.
10. **Pruebas sin internet.** Las respuestas externas se simulan mediante
    bindings locales.

## Dependencias de Fase 1

- `httr2`: API y descargas HTTP.
- `digest`: SHA-256.
- `DBI` y `duckdb`: apertura y validación de la base.
- `fs`: rutas y sistema de archivos.
- `jsonlite`: manifests.
- `rlang` y `cli`: errores y mensajes estructurados.
- `shiny` y `bslib`: interfaz local mínima de estado.
- `tibble`: representación estable de assets.

Las dependencias de NLP se añadirán únicamente cuando sean utilizadas.

## Árbol definitivo

```text
.Rbuildignore
.gitignore
DESCRIPTION
LICENSE
LICENSE.md
NAMESPACE
NEWS.md
PHASE1_ARCHITECTURE.md
R/checksums.R
R/config.R
R/database-download.R
R/database-info.R
R/database-update.R
R/database-validation.R
R/github-release.R
R/package.R
R/paths.R
R/run-app.R
R/utils.R
R/zzz.R
README.md
UniLitR.Rproj
data-raw/input/.gitkeep
inst/app/app.R
inst/extdata/default-config.json
man/UniLitR-package.Rd
man/check_database_update.Rd
man/database_info.Rd
man/remove_local_database.Rd
man/run_app.Rd
man/update_database.Rd
tests/testthat.R
tests/testthat/helper-database.R
tests/testthat/test-checksums.R
tests/testthat/test-config-paths.R
tests/testthat/test-database-validation.R
tests/testthat/test-install-rollback.R
tests/testthat/test-manifest.R
tests/testthat/test-release-parsing.R
tests/testthat/test-version-update.R
```
```

## `R/checksums.R`

```r
#' Calculate a file SHA-256 checksum
#' @noRd
sha256_file <- function(path) {
  if (!file.exists(path)) {
    rlang::abort(
      sprintf("No existe el archivo `%s`.", path),
      class = "UniLitR_file_not_found"
    )
  }

  tolower(digest::digest(
    object = path,
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  ))
}

#' Parse a standard checksums file
#' @noRd
parse_checksums <- function(path) {
  if (!file.exists(path)) {
    rlang::abort(
      sprintf("No existe el archivo de checksums `%s`.", path),
      class = "UniLitR_checksum_file_not_found"
    )
  }

  lines <- trimws(readLines(path, warn = FALSE, encoding = "UTF-8"))
  lines <- lines[nzchar(lines) & !startsWith(lines, "#")]

  if (length(lines) == 0L) {
    rlang::abort(
      "El archivo de checksums está vacío.",
      class = "UniLitR_invalid_checksum_file"
    )
  }

  pattern <- "^([A-Fa-f0-9]{64})\\s+\\*?(.+)$"
  matches <- regexec(pattern, lines, perl = TRUE)
  parsed <- regmatches(lines, matches)
  valid <- lengths(parsed) == 3L

  if (!all(valid)) {
    rlang::abort(
      "El archivo de checksums contiene líneas con formato inválido.",
      class = "UniLitR_invalid_checksum_file"
    )
  }

  hashes <- vapply(parsed, `[[`, character(1), 2L)
  names(hashes) <- basename(vapply(parsed, `[[`, character(1), 3L))
  tolower(hashes)
}

#' Verify a file checksum
#' @noRd
verify_checksum <- function(path, expected) {
  ensure_scalar_character(expected, "expected")
  expected <- tolower(sub("^sha256:", "", trimws(expected)))

  if (!grepl("^[a-f0-9]{64}$", expected)) {
    rlang::abort(
      "El checksum esperado no es un SHA-256 válido.",
      class = "UniLitR_invalid_checksum"
    )
  }

  actual <- sha256_file(path)
  if (!identical(actual, expected)) {
    rlang::abort(
      c(
        "La verificación SHA-256 falló.",
        "x" = paste("Esperado:", expected),
        "x" = paste("Calculado:", actual)
      ),
      class = "UniLitR_checksum_mismatch",
      expected = expected,
      actual = actual
    )
  }

  invisible(TRUE)
}
```

## `R/config.R`

```r
.unilitr_package_name <- "UniLitR"

#' Central package configuration
#'
#' This internal function is the only location that defines the package name,
#' GitHub repository, release asset names, and database schema version. Values
#' can be overridden with R options, which is useful for private repositories,
#' tests, and development forks.
#'
#' @return A named list.
#' @noRd
package_config <- function() {
  list(
    package_name = getOption("UniLitR.package_name", .unilitr_package_name),
    github_owner = getOption(
      "UniLitR.github_owner",
      "REPLACE_GITHUB_OWNER"
    ),
    github_repo = getOption(
      "UniLitR.github_repo",
      "REPLACE_GITHUB_REPOSITORY"
    ),
    github_api_base = getOption(
      "UniLitR.github_api_base",
      "https://api.github.com"
    ),
    github_api_version = getOption(
      "UniLitR.github_api_version",
      "2026-03-10"
    ),
    database_asset_pattern = getOption(
      "UniLitR.database_asset_pattern",
      "^university_articles_[0-9]{4}-[0-9]{2}\\.duckdb$"
    ),
    manifest_asset = getOption(
      "UniLitR.manifest_asset",
      "manifest.json"
    ),
    checksum_asset = getOption(
      "UniLitR.checksum_asset",
      "checksums.txt"
    ),
    default_model = getOption(
      "UniLitR.default_model",
      "intfloat/multilingual-e5-base"
    ),
    schema_version = getOption("UniLitR.schema_version", "1.0"),
    release_scan_limit = as.integer(
      getOption("UniLitR.release_scan_limit", 30L)
    )
  )
}

#' Validate GitHub configuration
#' @return The configuration invisibly.
#' @noRd
validate_github_config <- function(config = package_config()) {
  placeholders <- c(
    "REPLACE_GITHUB_OWNER",
    "REPLACE_GITHUB_REPOSITORY"
  )

  invalid <- is.null(config$github_owner) ||
    is.null(config$github_repo) ||
    !nzchar(config$github_owner) ||
    !nzchar(config$github_repo) ||
    config$github_owner %in% placeholders ||
    config$github_repo %in% placeholders

  if (invalid) {
    rlang::abort(
      c(
        "No se ha configurado el repositorio de datos de GitHub.",
        "i" = paste0(
          "Edite `package_config()` o defina las opciones ",
          "`UniLitR.github_owner` y `UniLitR.github_repo`."
        )
      ),
      class = "UniLitR_github_not_configured"
    )
  }

  invisible(config)
}

#' Installed package version without failing in development mode
#' @noRd
installed_package_version <- function() {
  tryCatch(
    as.character(utils::packageVersion(.unilitr_package_name)),
    error = function(e) "0.1.0.9000"
  )
}
```

## `R/database-download.R`

```r
#' Read and validate a manifest file
#' @noRd
read_manifest_file <- function(path) {
  if (!file.exists(path)) {
    rlang::abort(
      sprintf("No existe el manifest `%s`.", path),
      class = "UniLitR_manifest_not_found"
    )
  }

  manifest <- tryCatch(
    jsonlite::read_json(path, simplifyVector = TRUE),
    error = function(e) {
      rlang::abort(
        c("No fue posible leer el manifest JSON.", "x" = conditionMessage(e)),
        class = "UniLitR_invalid_manifest",
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
        class = "UniLitR_manifest_not_found"
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
        class = "UniLitR_release_changed"
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
      class = "UniLitR_invalid_manifest"
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
      class = "UniLitR_invalid_checksum_file"
    )
  }

  if (!identical(tolower(checksum_from_file), tolower(manifest$sha256))) {
    rlang::abort(
      "El checksum del manifest y el de checksums.txt no coinciden.",
      class = "UniLitR_checksum_metadata_mismatch"
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
    class = "UniLitR_release_bundle"
  )
}

#' Install a validated bundle without destroying the previous database
#' @noRd
install_release_bundle <- function(bundle, manifest_writer = write_local_manifest) {
  stopifnot(inherits(bundle, "UniLitR_release_bundle"))

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
          class = "UniLitR_old_database_cleanup_warning"
        )
      }
    )
  }

  invisible(target_database)
}
```

## `R/database-info.R`

```r
#' Information about the locally installed bibliographic database
#'
#' @return An object of class `UniLitR_database_info`.
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
        embedding_dimensions = NA_integer_,
        embedding_normalized = NA,
        database_schema_version = NA_character_,
        minimum_package_version = NA_character_,
        compatible = NA
      ),
      class = "UniLitR_database_info"
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
      embedding_dimensions = manifest$embedding_dimensions,
      embedding_normalized = manifest$embedding_normalized,
      database_schema_version = manifest$database_schema_version,
      minimum_package_version = manifest$minimum_package_version,
      compatible = compatible
    ),
    class = "UniLitR_database_info"
  )
}

#' @export
print.UniLitR_database_info <- function(x, ...) {
  if (!isTRUE(x$installed)) {
    cat("Base bibliográfica UniLitR: no instalada\n")
    return(invisible(x))
  }

  cat("Base bibliográfica UniLitR\n")
  cat("  Ruta:                 ", x$path, "\n", sep = "")
  cat("  Versión de datos:     ", x$version, "\n", sep = "")
  cat("  Fecha de publicación: ", x$published_at, "\n", sep = "")
  cat("  Artículos:            ", format(x$number_of_articles, big.mark = ","), "\n", sep = "")
  cat("  Tamaño:               ", x$size, "\n", sep = "")
  cat("  Modelo de embeddings: ", x$embedding_model, "\n", sep = "")
  cat("  Dimensiones:          ", x$embedding_dimensions, "\n", sep = "")
  cat("  Esquema:              ", x$database_schema_version, "\n", sep = "")
  cat("  Compatible:           ", if (isTRUE(x$compatible)) "sí" else "no", "\n", sep = "")
  invisible(x)
}

#' Remove locally managed bibliographic database files
#'
#' Removes only the local data files and manifest managed by `UniLitR`. It does
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
        class = "UniLitR_confirmation_required"
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
```

## `R/database-update.R`

```r
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
```

## `R/database-validation.R`

```r
required_database_tables <- function() {
  c("articles", "embeddings", "database_metadata")
}

required_article_columns <- function() {
  c(
    "article_id",
    "title",
    "title_normalized",
    "authors",
    "abstract",
    "keywords",
    "doi",
    "doi_normalized",
    "year",
    "source_title",
    "theme_text",
    "purpose_text",
    "method_text",
    "data_text",
    "context_text",
    "missing_abstract",
    "content_hash",
    "created_at",
    "updated_at"
  )
}

#' Open the local DuckDB database
#' @noRd
open_database <- function(path = local_database_path(must_exist = TRUE), read_only = TRUE) {
  DBI::dbConnect(
    duckdb::duckdb(),
    dbdir = path,
    read_only = isTRUE(read_only)
  )
}

#' Close a DuckDB connection
#' @noRd
close_database <- function(connection) {
  if (!is.null(connection) && DBI::dbIsValid(connection)) {
    DBI::dbDisconnect(connection)
  }
  invisible(NULL)
}

#' Check required DuckDB tables
#' @noRd
check_required_tables <- function(connection) {
  available <- DBI::dbListTables(connection)
  missing <- setdiff(required_database_tables(), available)

  if (length(missing) > 0L) {
    rlang::abort(
      c(
        "La base DuckDB no tiene todas las tablas requeridas.",
        "x" = paste("Faltan:", paste(missing, collapse = ", "))
      ),
      class = "UniLitR_invalid_database_schema"
    )
  }

  invisible(TRUE)
}

#' Read database metadata into a named list
#' @noRd
read_database_metadata <- function(connection) {
  metadata <- DBI::dbGetQuery(
    connection,
    "SELECT key, value FROM database_metadata"
  )

  if (!all(c("key", "value") %in% names(metadata))) {
    rlang::abort(
      "La tabla `database_metadata` debe contener `key` y `value`.",
      class = "UniLitR_invalid_database_schema"
    )
  }

  stats::setNames(as.list(as.character(metadata$value)), metadata$key)
}

#' Validate manifest structure and compatibility
#' @noRd
validate_manifest <- function(manifest) {
  required <- c(
    "data_version",
    "published_at",
    "database_file",
    "database_schema_version",
    "number_of_articles",
    "embedding_model",
    "embedding_dimensions",
    "embedding_normalized",
    "query_prefix",
    "passage_prefix",
    "minimum_package_version",
    "sha256"
  )

  missing <- setdiff(required, names(manifest))
  if (length(missing) > 0L) {
    rlang::abort(
      c(
        "El manifest no contiene todos los campos requeridos.",
        "x" = paste("Faltan:", paste(missing, collapse = ", "))
      ),
      class = "UniLitR_invalid_manifest"
    )
  }

  if (!grepl("^[0-9]{4}\\.[0-9]{2}$", manifest$data_version)) {
    rlang::abort(
      "`data_version` debe usar el formato YYYY.MM.",
      class = "UniLitR_invalid_manifest"
    )
  }

  if (!identical(basename(manifest$database_file), manifest$database_file)) {
    rlang::abort(
      "`database_file` debe contener solo el nombre del archivo.",
      class = "UniLitR_invalid_manifest"
    )
  }

  if (!grepl(package_config()$database_asset_pattern, manifest$database_file)) {
    rlang::abort(
      "El nombre de la base no coincide con el patrón configurado.",
      class = "UniLitR_invalid_manifest"
    )
  }

  hash <- tolower(sub("^sha256:", "", manifest$sha256))
  if (!grepl("^[a-f0-9]{64}$", hash)) {
    rlang::abort(
      "`sha256` no es un hash SHA-256 válido.",
      class = "UniLitR_invalid_manifest"
    )
  }

  manifest$sha256 <- hash
  raw_normalized <- manifest$embedding_normalized
  manifest$number_of_articles <- as.numeric(manifest$number_of_articles)
  manifest$embedding_dimensions <- as.integer(manifest$embedding_dimensions)

  if (is.na(manifest$number_of_articles) || manifest$number_of_articles < 0) {
    rlang::abort(
      "`number_of_articles` debe ser un número no negativo.",
      class = "UniLitR_invalid_manifest"
    )
  }
  if (is.na(manifest$embedding_dimensions) || manifest$embedding_dimensions < 1L) {
    rlang::abort(
      "`embedding_dimensions` debe ser un entero positivo.",
      class = "UniLitR_invalid_manifest"
    )
  }
  if (!is.logical(raw_normalized) || length(raw_normalized) != 1L || is.na(raw_normalized)) {
    rlang::abort(
      "`embedding_normalized` debe ser TRUE o FALSE.",
      class = "UniLitR_invalid_manifest"
    )
  }
  manifest$embedding_normalized <- raw_normalized

  minimum <- as.character(manifest$minimum_package_version)
  current <- installed_package_version()
  if (utils::compareVersion(current, minimum) < 0L) {
    rlang::abort(
      c(
        "La base requiere una versión más reciente de UniLitR.",
        "x" = paste("Versión instalada:", current),
        "i" = paste("Versión mínima:", minimum)
      ),
      class = "UniLitR_package_version_incompatible"
    )
  }

  if (!identical(
    as.character(manifest$database_schema_version),
    as.character(package_config()$schema_version)
  )) {
    rlang::abort(
      c(
        "La versión del esquema de datos no es compatible.",
        "x" = paste(
          "Esquema de la base:", manifest$database_schema_version
        ),
        "i" = paste("Esquema esperado:", package_config()$schema_version)
      ),
      class = "UniLitR_database_schema_incompatible"
    )
  }

  manifest
}

#' Validate a DuckDB file
#' @noRd
validate_database <- function(path, manifest = NULL) {
  if (!file.exists(path)) {
    rlang::abort(
      sprintf("No existe la base `%s`.", path),
      class = "UniLitR_database_not_found"
    )
  }

  if (!is.null(manifest)) manifest <- validate_manifest(manifest)

  connection <- tryCatch(
    open_database(path = path, read_only = TRUE),
    error = function(e) {
      rlang::abort(
        c(
          "No fue posible abrir la base DuckDB.",
          "x" = conditionMessage(e)
        ),
        class = "UniLitR_invalid_database",
        parent = e
      )
    }
  )
  on.exit(close_database(connection), add = TRUE)

  check_required_tables(connection)

  article_columns <- DBI::dbListFields(connection, "articles")
  missing_columns <- setdiff(required_article_columns(), article_columns)
  if (length(missing_columns) > 0L) {
    rlang::abort(
      c(
        "La tabla `articles` no tiene todas las columnas requeridas.",
        "x" = paste("Faltan:", paste(missing_columns, collapse = ", "))
      ),
      class = "UniLitR_invalid_database_schema"
    )
  }

  embedding_columns <- DBI::dbListFields(connection, "embeddings")
  required_embeddings <- c(
    "article_id",
    "dimension",
    "model_name",
    "embedding_dimensions",
    "normalized",
    "embedding_blob",
    "content_hash"
  )
  missing_embeddings <- setdiff(required_embeddings, embedding_columns)
  if (length(missing_embeddings) > 0L) {
    rlang::abort(
      c(
        "La tabla `embeddings` no tiene todas las columnas requeridas.",
        "x" = paste("Faltan:", paste(missing_embeddings, collapse = ", "))
      ),
      class = "UniLitR_invalid_database_schema"
    )
  }

  metadata <- read_database_metadata(connection)
  number_of_articles <- DBI::dbGetQuery(
    connection,
    "SELECT COUNT(*) AS n FROM articles"
  )$n[[1L]]

  if (!is.null(manifest) &&
      !isTRUE(all.equal(as.numeric(number_of_articles), manifest$number_of_articles))) {
    rlang::abort(
      c(
        "El número de artículos no coincide con el manifest.",
        "x" = paste("Manifest:", manifest$number_of_articles),
        "x" = paste("DuckDB:", number_of_articles)
      ),
      class = "UniLitR_database_manifest_mismatch"
    )
  }

  if (!is.null(metadata$database_schema_version) &&
      !identical(
        as.character(metadata$database_schema_version),
        package_config()$schema_version
      )) {
    rlang::abort(
      "La metadata interna declara un esquema incompatible.",
      class = "UniLitR_database_schema_incompatible"
    )
  }

  structure(
    list(
      valid = TRUE,
      path = fs::path_abs(path),
      tables = DBI::dbListTables(connection),
      number_of_articles = as.numeric(number_of_articles),
      metadata = metadata
    ),
    class = "UniLitR_database_validation"
  )
}
```

## `R/github-release.R`

```r
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

#' Does a release contain a complete UniLitR data bundle?
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
      class = "UniLitR_release_not_found"
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
      class = "UniLitR_release_asset_error"
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
      class = "UniLitR_release_asset_error"
    )
  }

  fs::dir_create(dirname(destination), recurse = TRUE)
  request <- github_request(url, accept = accept)
  if (!isTRUE(quiet)) request <- httr2::req_progress(request, type = "down")

  request |> httr2::req_perform(path = destination)

  if (!file.exists(destination) || file.info(destination)$size <= 0) {
    rlang::abort(
      sprintf("La descarga de `%s` no produjo un archivo válido.", asset_name),
      class = "UniLitR_download_error"
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
```

## `R/package.R`

```r
#' UniLitR: local recommendation of institutional scientific literature
#'
#' `UniLitR` provides the local database lifecycle used by the article
#' recommendation application: discovery of data releases, verified downloads,
#' DuckDB validation, local version management, and local Shiny startup.
#'
#' @keywords internal
"_PACKAGE"
```

## `R/paths.R`

```r
#' User data directory
#' @noRd
user_data_dir <- function(create = TRUE) {
  configured <- getOption("UniLitR.data_dir", NULL)
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
  configured <- getOption("UniLitR.cache_dir", NULL)
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
      class = "UniLitR_database_not_found"
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
```

## `R/run-app.R`

```r
#' Select the recommendation engine available in the current phase
#' @noRd
select_engine <- function(engine = c("auto", "semantic", "lexical")) {
  engine <- match.arg(engine)

  if (identical(engine, "semantic")) {
    rlang::abort(
      c(
        "El motor semántico todavía no está instalado en esta Fase 1.",
        "i" = "Use temporalmente `engine = \"lexical\"`."
      ),
      class = "UniLitR_semantic_engine_unavailable"
    )
  }

  if (identical(engine, "auto")) "lexical" else engine
}

confirm_initial_download <- function() {
  if (!interactive()) {
    rlang::abort(
      c(
        "La base bibliográfica todavía no está instalada.",
        "i" = "Ejecute `update_database()` antes de `run_app()`."
      ),
      class = "UniLitR_database_not_found"
    )
  }

  answer <- utils::menu(
    c("Descargar la base ahora", "Cancelar"),
    title = paste(
      "UniLitR necesita descargar la base bibliográfica desde GitHub Releases."
    )
  )
  identical(answer, 1L)
}

#' Run the local UniLitR Shiny application
#'
#' Ensures that a verified local bibliographic database is available, checks
#' for updates when requested, and launches the packaged Shiny application in
#' a local browser session.
#'
#' @param engine Recommendation engine. Phase 1 provides the application and
#'   database lifecycle; the lexical and semantic rankers are added in later
#'   phases. `"auto"` currently resolves to `"lexical"`.
#' @param check_updates Logical. Check GitHub Releases before opening the app.
#' @param launch.browser Logical or function passed to [shiny::runApp()].
#' @param host Local host passed to [shiny::runApp()].
#' @param port Optional local port. `NULL` lets Shiny select a free port.
#'
#' @return The value returned by [shiny::runApp()], invisibly.
#' @export
#' @examples
#' \dontrun{
#' run_app(engine = "lexical")
#' }
run_app <- function(
    engine = c("auto", "semantic", "lexical"),
    check_updates = TRUE,
    launch.browser = TRUE,
    host = "127.0.0.1",
    port = NULL) {
  engine <- select_engine(engine)

  local_status <- tryCatch(
    database_info(),
    error = function(e) NULL
  )

  if (is.null(local_status) || !isTRUE(local_status$installed)) {
    if (!confirm_initial_download()) {
      rlang::abort("La aplicación no puede iniciarse sin una base local válida.")
    }
    update_database(force = TRUE)
  }

  update_status <- if (isTRUE(check_updates)) {
    check_database_update()
  } else {
    list(update_available = FALSE, error = NULL)
  }

  app_dir <- system.file("app", package = .unilitr_package_name)
  if (!nzchar(app_dir) || !dir.exists(app_dir)) {
    rlang::abort(
      "No se encontró la aplicación Shiny incluida en el paquete.",
      class = "UniLitR_app_not_found"
    )
  }

  old_options <- options(UniLitR.runtime = list(
    engine = engine,
    update_status = update_status,
    package_version = installed_package_version()
  ))
  on.exit(options(old_options), add = TRUE)

  arguments <- list(
    appDir = app_dir,
    launch.browser = launch.browser,
    host = host
  )
  if (!is.null(port)) arguments$port <- as.integer(port)

  invisible(do.call(shiny::runApp, arguments))
}
```

## `R/utils.R`

```r
`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L) y else x
}

is_blank_string <- function(x) {
  is.null(x) || length(x) == 0L || is.na(x[[1L]]) || !nzchar(trimws(x[[1L]]))
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

ensure_scalar_character <- function(x, arg) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x)) {
    rlang::abort(
      sprintf("`%s` debe ser una cadena de caracteres no vacía.", arg),
      class = "UniLitR_invalid_argument"
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
      class = "UniLitR_file_move_error"
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
```

## `R/zzz.R`

```r
.onLoad <- function(libname, pkgname) {
  # Phase 1 intentionally performs no network access, Python initialization,
  # model download, or write operation during package loading.
  invisible(NULL)
}
```

## `README.md`

```markdown
# UniLitR

`UniLitR` is a local R/Shiny application for recommending institutional
scientific literature. This repository currently contains **Phase 1**, which
implements the secure lifecycle of a separately versioned DuckDB database:

- locate the active local database;
- discover the newest complete data release on GitHub;
- download `manifest.json`, `checksums.txt`, and the DuckDB asset;
- verify SHA-256 integrity;
- validate required DuckDB tables and columns;
- install updates atomically with rollback protection;
- store files in `tools::R_user_dir()`;
- open a local Shiny status interface.

## Required configuration

Replace the placeholders in `R/config.R` and `DESCRIPTION`, or configure a fork
at runtime:

```r
options(
  UniLitR.github_owner = "your-organization",
  UniLitR.github_repo = "your-data-repository"
)
```

For private repositories, define a read-only token outside the source code:

```r
Sys.setenv(GITHUB_PAT = "...")
```

Do not commit the token to Git.

## Install from GitHub

```r
install.packages("pak")
pak::pkg_install("REPLACE_GITHUB_OWNER/REPLACE_GITHUB_REPOSITORY")
```

## Use

```r
library(UniLitR)

check_database_update()
update_database()
database_info()
run_app(engine = "lexical")
```

The Phase 1 Shiny interface displays database status and supports the update
modal. The lexical ranking engine, semantic engine, full query form, and result
table are introduced in subsequent phases.

## Data release contract

Each complete data release must contain:

```text
university_articles_YYYY-MM.duckdb
manifest.json
checksums.txt
```

The repository can be public, or private when the user supplies `GITHUB_PAT`.
The package scans recent non-draft, non-prerelease releases and selects the
newest one containing all required assets.

## Local storage

Data are stored under:

```r
tools::R_user_dir("UniLitR", "data")
```

The package never writes into its installation directory.

## Responsible use

The final application will recommend potentially relevant literature. Each
researcher remains responsible for reading a paper and citing it only when it
contributes substantively to the new research.
```

## `UniLitR.Rproj`

```text
Version: 1.0

RestoreWorkspace: No
SaveWorkspace: No
AlwaysSaveHistory: No

EnableCodeIndexing: Yes
UseSpacesForTab: Yes
NumSpacesForTab: 2
Encoding: UTF-8

RnwWeave: Sweave
LaTeX: pdfLaTeX

BuildType: Package
PackageUseDevtools: Yes
PackageInstallArgs: --no-multiarch --with-keep.source
PackageRoxygenize: rd,collate,namespace
```

## `data-raw/input/.gitkeep`

```text

```

## `inst/app/app.R`

```r
`%||%` <- function(x, y) if (is.null(x) || length(x) == 0L) y else x

runtime <- getOption(
  "UniLitR.runtime",
  list(
    engine = "lexical",
    update_status = list(update_available = FALSE, error = NULL),
    package_version = NA_character_
  )
)

ui <- bslib::page_fillable(
  title = "UniLitR",
  theme = bslib::bs_theme(version = 5, bootswatch = "flatly"),
  bslib::layout_column_wrap(
    width = 1,
    bslib::card(
      bslib::card_header("UniLitR — Fase 1"),
      shiny::h2("Base bibliográfica local verificada"),
      shiny::p(
        paste(
          "Esta primera fase implementa la descarga, validación, actualización",
          "y administración segura de la base DuckDB."
        )
      ),
      shiny::uiOutput("database_summary"),
      shiny::hr(),
      shiny::p(
        shiny::strong("Motor seleccionado: "),
        runtime$engine
      ),
      shiny::p(
        "Los formularios de consulta y el ranking se incorporarán en las fases 3 a 5."
      )
    ),
    bslib::card(
      bslib::card_header("Principio de uso responsable"),
      shiny::tags$blockquote(
        paste(
          "Las recomendaciones se basan en similitud temática, metodológica y",
          "contextual. El investigador debe revisar cada artículo y citarlo",
          "únicamente cuando contribuya de manera sustantiva a su investigación."
        )
      )
    )
  )
)

server <- function(input, output, session) {
  info <- shiny::reactiveVal(UniLitR::database_info())

  output$database_summary <- shiny::renderUI({
    current <- info()
    if (!isTRUE(current$installed)) {
      return(shiny::div(class = "alert alert-danger", "Base no instalada."))
    }

    shiny::tagList(
      shiny::p(shiny::strong("Versión: "), current$version),
      shiny::p(
        shiny::strong("Artículos: "),
        format(current$number_of_articles, big.mark = ",")
      ),
      shiny::p(shiny::strong("Archivo: "), current$file_name),
      shiny::p(shiny::strong("Tamaño: "), current$size),
      shiny::p(shiny::strong("Esquema: "), current$database_schema_version)
    )
  })

  shiny::observeEvent(TRUE, {
    status <- runtime$update_status

    if (isTRUE(status$update_available)) {
      manifest <- status$manifest
      shiny::showModal(shiny::modalDialog(
        title = "Se encontró una nueva base bibliográfica",
        shiny::p(
          shiny::strong("Versión instalada: "),
          if (is.null(status$installed_version) || is.na(status$installed_version)) "No instalada" else status$installed_version
        ),
        shiny::p(
          shiny::strong("Versión disponible: "),
          status$available_version
        ),
        shiny::p(
          shiny::strong("Artículos en la nueva base: "),
          format(manifest$number_of_articles, big.mark = ",")
        ),
        shiny::p(
          shiny::strong("Fecha de publicación: "),
          manifest$published_at
        ),
        footer = shiny::tagList(
          shiny::modalButton("Continuar con versión instalada"),
          shiny::actionButton("update_now", "Actualizar ahora", class = "btn-primary")
        ),
        easyClose = FALSE
      ))
    } else if (!is.null(status$error) && nzchar(status$error)) {
      shiny::showNotification(
        paste("No fue posible comprobar actualizaciones:", status$error),
        type = "warning",
        duration = 8
      )
    }
  }, once = TRUE)

  shiny::observeEvent(input$update_now, {
    shiny::withProgress(message = "Actualizando la base", value = 0, {
      result <- tryCatch(
        {
          shiny::incProgress(0.2, detail = "Descargando y verificando")
          UniLitR::update_database(force = TRUE, quiet = TRUE)
        },
        error = function(e) e
      )

      if (inherits(result, "error")) {
        shiny::showNotification(
          conditionMessage(result),
          type = "error",
          duration = NULL
        )
      } else {
        shiny::incProgress(0.8, detail = "Actualización completada")
        info(UniLitR::database_info())
        shiny::removeModal()
        shiny::showNotification(
          "La base bibliográfica fue actualizada.",
          type = "message"
        )
      }
    })
  })
}

shiny::shinyApp(ui, server)
```

## `inst/extdata/default-config.json`

```json
{
  "package_name": "UniLitR",
  "github_owner": "REPLACE_GITHUB_OWNER",
  "github_repo": "REPLACE_GITHUB_REPOSITORY",
  "database_asset_pattern": "^university_articles_[0-9]{4}-[0-9]{2}\\.duckdb$",
  "manifest_asset": "manifest.json",
  "checksum_asset": "checksums.txt",
  "default_model": "intfloat/multilingual-e5-base",
  "schema_version": "1.0"
}
```

## `man/UniLitR-package.Rd`

```r
\name{UniLitR-package}
\alias{UniLitR}
\alias{UniLitR-package}
\title{UniLitR: local recommendation of institutional scientific literature}
\description{
Infrastructure for verified local DuckDB data releases and a local Shiny
application used by the UniLitR recommendation system.
}
\docType{package}
\keyword{internal}
```

## `man/check_database_update.Rd`

```r
\name{check_database_update}
\alias{check_database_update}
\title{Check whether a newer bibliographic database is available}
\usage{check_database_update()}
\value{A named list describing installed and available versions.}
\description{Consults GitHub Releases without invalidating a working local database when the network is unavailable.}
\examples{\dontrun{check_database_update()}}
```

## `man/database_info.Rd`

```r
\name{database_info}
\alias{database_info}
\alias{print.UniLitR_database_info}
\title{Information about the locally installed bibliographic database}
\usage{
database_info()
\method{print}{UniLitR_database_info}(x, ...)
}
\arguments{
\item{x}{A database information object.}
\item{...}{Unused.}
}
\value{An object of class \code{UniLitR_database_info}.}
\description{Reports database path, version, size, article count, checksum, embedding metadata, schema, and compatibility.}
\examples{\dontrun{database_info()}}
```

## `man/remove_local_database.Rd`

```r
\name{remove_local_database}
\alias{remove_local_database}
\title{Remove locally managed bibliographic database files}
\usage{remove_local_database(force = FALSE)}
\arguments{\item{force}{Skip the interactive confirmation.}}
\value{Invisibly, the paths that existed before removal.}
\description{Removes only the local database, manifest, and staging directories. It does not remove semantic models or other cache content.}
\examples{\dontrun{remove_local_database()}}
```

## `man/run_app.Rd`

```r
\name{run_app}
\alias{run_app}
\title{Run the local UniLitR Shiny application}
\usage{
run_app(
  engine = c("auto", "semantic", "lexical"),
  check_updates = TRUE,
  launch.browser = TRUE,
  host = "127.0.0.1",
  port = NULL
)
}
\arguments{
\item{engine}{Recommendation engine. In Phase 1, \code{"auto"} resolves to \code{"lexical"}.}
\item{check_updates}{Check GitHub Releases before opening the app.}
\item{launch.browser}{Value passed to \code{shiny::runApp()}.}
\item{host}{Local host passed to \code{shiny::runApp()}.}
\item{port}{Optional local port.}
}
\description{Ensures a verified local database is present and opens the packaged Shiny application.}
\examples{
\dontrun{run_app(engine = "lexical")}
}
```

## `man/update_database.Rd`

```r
\name{update_database}
\alias{update_database}
\title{Download and install the latest bibliographic database}
\usage{update_database(force = FALSE, quiet = FALSE)}
\arguments{
\item{force}{Reinstall even when the installed data version is current.}
\item{quiet}{Suppress informational messages and progress.}
}
\value{Invisibly, a list describing the update.}
\description{Downloads a staged GitHub Release bundle, verifies its checksum and DuckDB schema, and installs it with rollback protection.}
\examples{\dontrun{update_database()}}
```

## `tests/testthat/helper-database.R`

```r
create_test_manifest <- function(database_file, sha256, n = 1) {
  list(
    data_version = "2026.07",
    published_at = "2026-07-15",
    database_file = database_file,
    database_schema_version = "1.0",
    number_of_articles = n,
    embedding_model = "intfloat/multilingual-e5-base",
    embedding_dimensions = 768L,
    embedding_normalized = TRUE,
    query_prefix = "query: ",
    passage_prefix = "passage: ",
    minimum_package_version = "0.1.0",
    sha256 = sha256
  )
}

create_test_database <- function(path, n = 1L) {
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  DBI::dbExecute(con, paste(
    "CREATE TABLE articles (",
    "article_id VARCHAR, title VARCHAR, title_normalized VARCHAR,",
    "authors VARCHAR, abstract VARCHAR, keywords VARCHAR, doi VARCHAR,",
    "doi_normalized VARCHAR, year INTEGER, source_title VARCHAR,",
    "theme_text VARCHAR, purpose_text VARCHAR, method_text VARCHAR,",
    "data_text VARCHAR, context_text VARCHAR, missing_abstract BOOLEAN,",
    "content_hash VARCHAR, created_at TIMESTAMP, updated_at TIMESTAMP)"
  ))

  if (n > 0L) {
    for (i in seq_len(n)) {
      DBI::dbExecute(con, paste0(
        "INSERT INTO articles VALUES ('id", i, "', 'Title ", i,
        "', 'title ", i, "', 'Author', 'Abstract', 'keyword', NULL, NULL,",
        " 2026, 'Journal', 'theme', 'purpose', 'method', 'data', 'context',",
        " FALSE, 'hash", i, "', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
      ))
    }
  }

  DBI::dbExecute(con, paste(
    "CREATE TABLE embeddings (",
    "article_id VARCHAR, dimension VARCHAR, model_name VARCHAR,",
    "embedding_dimensions INTEGER, normalized BOOLEAN,",
    "embedding_blob BLOB, content_hash VARCHAR)"
  ))

  DBI::dbExecute(con, "CREATE TABLE database_metadata (key VARCHAR, value VARCHAR)")
  metadata <- data.frame(
    key = c("data_version", "database_schema_version", "number_of_articles"),
    value = c("2026.07", "1.0", as.character(n)),
    stringsAsFactors = FALSE
  )
  DBI::dbAppendTable(con, "database_metadata", metadata)

  invisible(path)
}
```

## `tests/testthat/test-checksums.R`

```r
test_that("SHA-256 calculation and verification are reproducible", {
  path <- tempfile()
  writeLines("UniLitR", path, useBytes = TRUE)

  hash <- UniLitR:::sha256_file(path)
  expect_match(hash, "^[a-f0-9]{64}$")
  expect_invisible(UniLitR:::verify_checksum(path, hash))
  expect_error(
    UniLitR:::verify_checksum(path, paste(rep("0", 64), collapse = "")),
    class = "UniLitR_checksum_mismatch"
  )
})

test_that("checksums.txt is parsed by file name", {
  path <- tempfile()
  hash <- paste(rep("a", 64), collapse = "")
  writeLines(paste(hash, " university_articles_2026-07.duckdb"), path)

  parsed <- UniLitR:::parse_checksums(path)
  expect_identical(
    unname(parsed[["university_articles_2026-07.duckdb"]]),
    hash
  )
})
```

## `tests/testthat/test-config-paths.R`

```r
test_that("configuration can be overridden centrally", {
  withr::local_options(list(
    UniLitR.github_owner = "example-owner",
    UniLitR.github_repo = "example-repo"
  ))

  config <- UniLitR:::package_config()
  expect_identical(config$package_name, "UniLitR")
  expect_identical(config$github_owner, "example-owner")
  expect_identical(config$github_repo, "example-repo")
})

test_that("data and cache paths support isolated overrides", {
  root <- withr::local_tempdir()
  data_dir <- file.path(root, "data")
  cache_dir <- file.path(root, "cache")
  withr::local_options(list(
    UniLitR.data_dir = data_dir,
    UniLitR.cache_dir = cache_dir
  ))

  expect_identical(UniLitR:::user_data_dir(), fs::path_abs(data_dir))
  expect_identical(UniLitR:::user_cache_dir(), fs::path_abs(cache_dir))
  expect_true(dir.exists(data_dir))
  expect_true(dir.exists(cache_dir))
})
```

## `tests/testthat/test-database-validation.R`

```r
test_that("a complete DuckDB database validates", {
  path <- tempfile(fileext = ".duckdb")
  create_test_database(path, n = 2L)
  hash <- UniLitR:::sha256_file(path)
  manifest <- create_test_manifest(basename(path), hash, n = 2L)
  manifest$database_file <- "university_articles_2026-07.duckdb"

  # Validation checks database content; the file name itself is controlled by
  # the manifest installation layer.
  validation <- UniLitR:::validate_database(path, manifest = manifest)
  expect_true(validation$valid)
  expect_equal(validation$number_of_articles, 2)
})

test_that("missing required tables are rejected", {
  path <- tempfile(fileext = ".duckdb")
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = path)
  DBI::dbExecute(con, "CREATE TABLE articles (article_id VARCHAR)")
  DBI::dbDisconnect(con)

  expect_error(
    UniLitR:::validate_database(path),
    class = "UniLitR_invalid_database_schema"
  )
})
```

## `tests/testthat/test-install-rollback.R`

```r
test_that("failed manifest installation restores an existing database", {
  root <- withr::local_tempdir()
  withr::local_options(list(UniLitR.data_dir = root))

  database_name <- "university_articles_2026-07.duckdb"
  existing <- file.path(root, database_name)
  writeLines("old database", existing)

  staged_dir <- file.path(root, ".staging-test")
  dir.create(staged_dir)
  staged <- file.path(staged_dir, database_name)
  writeLines("new database", staged)

  hash <- UniLitR:::sha256_file(staged)
  manifest <- create_test_manifest(database_name, hash)
  bundle <- structure(
    list(
      staging_dir = staged_dir,
      database_path = staged,
      manifest_path = file.path(staged_dir, "manifest.json"),
      checksum_path = file.path(staged_dir, "checksums.txt"),
      manifest = manifest,
      validation = list(valid = TRUE),
      release = list()
    ),
    class = "UniLitR_release_bundle"
  )

  failing_writer <- function(manifest) stop("manifest failure")
  expect_error(
    UniLitR:::install_release_bundle(bundle, manifest_writer = failing_writer),
    "manifest failure"
  )
  expect_identical(readLines(existing), "old database")
})
```

## `tests/testthat/test-manifest.R`

```r
test_that("a valid manifest is normalized", {
  file <- "university_articles_2026-07.duckdb"
  hash <- paste(rep("b", 64), collapse = "")
  manifest <- create_test_manifest(file, hash)

  result <- UniLitR:::validate_manifest(manifest)
  expect_identical(result$data_version, "2026.07")
  expect_identical(result$embedding_dimensions, 768L)
  expect_true(result$embedding_normalized)
})

test_that("manifest rejects path traversal and invalid hashes", {
  manifest <- create_test_manifest(
    "../university_articles_2026-07.duckdb",
    paste(rep("c", 64), collapse = "")
  )
  expect_error(
    UniLitR:::validate_manifest(manifest),
    class = "UniLitR_invalid_manifest"
  )

  manifest <- create_test_manifest(
    "university_articles_2026-07.duckdb",
    "invalid"
  )
  expect_error(
    UniLitR:::validate_manifest(manifest),
    class = "UniLitR_invalid_manifest"
  )
})
```

## `tests/testthat/test-release-parsing.R`

```r
test_that("release payloads are converted and identified", {
  payload <- list(
    id = 1,
    tag_name = "data-2026.07",
    published_at = "2026-07-15T00:00:00Z",
    draft = FALSE,
    prerelease = FALSE,
    assets = list(
      list(
        name = "manifest.json",
        browser_download_url = "https://example.org/manifest.json",
        url = "https://api.example.org/1",
        size = 100,
        digest = NA_character_,
        content_type = "application/json"
      ),
      list(
        name = "checksums.txt",
        browser_download_url = "https://example.org/checksums.txt",
        url = "https://api.example.org/2",
        size = 100,
        digest = NA_character_,
        content_type = "text/plain"
      ),
      list(
        name = "university_articles_2026-07.duckdb",
        browser_download_url = "https://example.org/database.duckdb",
        url = "https://api.example.org/3",
        size = 1000,
        digest = paste0("sha256:", paste(rep("a", 64), collapse = "")),
        content_type = "application/octet-stream"
      )
    )
  )

  release <- UniLitR:::as_release_record(payload)
  expect_true(UniLitR:::is_data_release(release))
  expect_equal(nrow(release$assets), 3L)
})
```

## `tests/testthat/test-version-update.R`

```r
test_that("data versions compare in the expected direction", {
  expect_equal(UniLitR:::compare_data_versions("2026.04", "2026.07"), 1L)
  expect_equal(UniLitR:::compare_data_versions("2026.07", "2026.07"), 0L)
  expect_equal(UniLitR:::compare_data_versions("2026.08", "2026.07"), -1L)
  expect_equal(UniLitR:::compare_data_versions(NA_character_, "2026.07"), 1L)
})

test_that("offline update checks preserve local availability", {
  root <- withr::local_tempdir()
  withr::local_options(list(UniLitR.data_dir = root))

  local_mocked_bindings(
    github_latest_release = function() stop("offline"),
    .package = "UniLitR"
  )

  result <- check_database_update()
  expect_false(result$update_available)
  expect_match(result$error, "offline")
})
```

## `tests/testthat.R`

```r
library(testthat)
library(UniLitR)

test_check("UniLitR")
```
