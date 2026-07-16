.embedding_state <- new.env(parent = emptyenv())
.embedding_state$model <- NULL
.embedding_state$model_name <- NULL
.embedding_state$model_path <- NULL
.embedding_state$module <- NULL
.embedding_state$numpy <- NULL
.embedding_state$fallback_notified <- FALSE

semantic_root_dir <- function(create = TRUE) {
  path <- fs::path(user_cache_dir(create = create), "semantic")
  if (isTRUE(create)) fs::dir_create(path, recurse = TRUE)
  path
}

semantic_models_dir <- function(create = TRUE) {
  path <- fs::path(semantic_root_dir(create = create), "models")
  if (isTRUE(create)) fs::dir_create(path, recurse = TRUE)
  path
}

semantic_download_cache_dir <- function(create = TRUE) {
  path <- fs::path(semantic_root_dir(create = create), "downloads")
  if (isTRUE(create)) fs::dir_create(path, recurse = TRUE)
  path
}

semantic_engine_manifest_path <- function() {
  fs::path(semantic_root_dir(), "engine.json")
}

semantic_model_slug <- function(model_name) {
  ensure_scalar_character(model_name, "model_name")
  slug <- gsub("[^A-Za-z0-9._-]+", "--", model_name, perl = TRUE)
  slug <- gsub("^-+|-+$", "", slug)
  if (!nzchar(slug)) hash_text(model_name) else slug
}

semantic_model_dir <- function(
    model_name = package_config()$default_model,
    create_parent = TRUE) {
  fs::path(
    semantic_models_dir(create = create_parent),
    semantic_model_slug(model_name)
  )
}

semantic_model_manifest_path <- function(model_name = package_config()$default_model) {
  fs::path(semantic_model_dir(model_name), "similR-model.json")
}

read_json_safely <- function(path) {
  if (!file.exists(path)) return(NULL)
  tryCatch(
    jsonlite::read_json(path, simplifyVector = TRUE),
    error = function(e) NULL
  )
}

read_semantic_engine_manifest <- function() {
  read_json_safely(semantic_engine_manifest_path())
}

read_semantic_model_manifest <- function(model_name = package_config()$default_model) {
  read_json_safely(semantic_model_manifest_path(model_name))
}

semantic_model_downloaded <- function(model_name = package_config()$default_model) {
  path <- semantic_model_dir(model_name, create_parent = FALSE)
  dir.exists(path) &&
    file.exists(fs::path(path, "modules.json")) &&
    file.exists(fs::path(path, "similR-model.json"))
}

semantic_model_size <- function(model_name = package_config()$default_model) {
  path <- semantic_model_dir(model_name, create_parent = FALSE)
  if (!dir.exists(path)) return(0)
  info <- fs::dir_info(path, recurse = TRUE, type = "file", fail = FALSE)
  if (nrow(info) == 0L) return(0)
  sum(as.numeric(info$size), na.rm = TRUE)
}

declare_semantic_requirements <- function() {
  reticulate::py_require(
    packages = package_config()$python_packages,
    python_version = package_config()$python_version
  )
  invisible(TRUE)
}

python_version_supported <- function(version) {
  if (is.null(version) || length(version) == 0L || is.na(version)) return(FALSE)
  cleaned <- sub("[^0-9.].*$", "", as.character(version[[1L]]))
  tryCatch(
    utils::compareVersion(cleaned, "3.10") >= 0L,
    error = function(e) FALSE
  )
}

python_probe_script <- function() {
  c(
    "import importlib.util, json, sys",
    "try:",
    "    import importlib.metadata as metadata",
    "except Exception:",
    "    metadata = None",
    "def version(name):",
    "    if metadata is None:",
    "        return None",
    "    try:",
    "        return metadata.version(name)",
    "    except Exception:",
    "        return None",
    "payload = {",
    "    'python_version': '.'.join(map(str, sys.version_info[:3])),",
    "    'python_path': sys.executable,",
    "    'sentence_transformers_available': importlib.util.find_spec('sentence_transformers') is not None,",
    "    'numpy_available': importlib.util.find_spec('numpy') is not None,",
    "    'sentence_transformers_version': version('sentence-transformers'),",
    "    'numpy_version': version('numpy')",
    "}",
    "print(json.dumps(payload))"
  )
}

probe_python_executable <- function(python) {
  if (is_blank_string(python) || !file.exists(python)) return(NULL)
  script <- tempfile("similr-python-probe-", fileext = ".py")
  on.exit(unlink(script, force = TRUE), add = TRUE)
  writeLines(python_probe_script(), script, useBytes = TRUE)
  output <- tryCatch(
    suppressWarnings(system2(python, script, stdout = TRUE, stderr = TRUE)),
    error = function(e) character()
  )
  status <- attr(output, "status") %||% 0L
  if (!identical(as.integer(status), 0L) || length(output) == 0L) return(NULL)
  json_lines <- output[grepl("^\\s*\\{.*\\}\\s*$", output)]
  if (length(json_lines) == 0L) return(NULL)
  tryCatch(
    jsonlite::fromJSON(json_lines[[length(json_lines)]], simplifyVector = TRUE),
    error = function(e) NULL
  )
}

python_candidates <- function() {
  marker <- read_semantic_engine_manifest()
  candidates <- c(
    marker$python_path %||% character(),
    Sys.getenv("RETICULATE_PYTHON", unset = ""),
    unname(Sys.which(c("python3", "python")))
  )
  candidates <- candidates[nzchar(candidates) & candidates != "managed"]
  unique(fs::path_abs(candidates))
}

probe_available_python <- function() {
  if (reticulate::py_available(initialize = FALSE)) {
    config <- tryCatch(reticulate::py_config(), error = function(e) NULL)
    if (!is.null(config) && !is.null(config$python)) {
      probe <- probe_python_executable(config$python)
      if (!is.null(probe)) return(probe)
    }
  }

  candidates <- python_candidates()
  if (length(candidates) == 0L) return(NULL)
  for (candidate in candidates) {
    probe <- probe_python_executable(candidate)
    if (!is.null(probe)) return(probe)
  }
  NULL
}

write_semantic_engine_manifest <- function(probe) {
  manifest <- list(
    configured_at = utc_now(),
    python_path = probe$python_path,
    python_version = probe$python_version,
    sentence_transformers_available = isTRUE(probe$sentence_transformers_available),
    sentence_transformers_version = probe$sentence_transformers_version %||% NA_character_,
    numpy_available = isTRUE(probe$numpy_available),
    numpy_version = probe$numpy_version %||% NA_character_,
    requirements = package_config()$python_packages
  )
  atomic_write_json(manifest, semantic_engine_manifest_path())
  invisible(manifest)
}

initialize_semantic_runtime <- function(record = TRUE) {
  declare_semantic_requirements()

  result <- tryCatch({
    module <- reticulate::import("sentence_transformers", convert = TRUE)
    numpy <- reticulate::import("numpy", convert = TRUE)
    config <- reticulate::py_config()
    list(module = module, numpy = numpy, config = config)
  }, error = function(e) {
    rlang::abort(
      c(
        "No fue posible inicializar el motor semántico local.",
        "i" = "Ejecute `install_semantic_engine()` en una sesión con conexión a internet.",
        "x" = conditionMessage(e)
      ),
      class = "similR_semantic_initialization_error",
      parent = e
    )
  })

  version <- as.character(result$config$version)
  if (!python_version_supported(version)) {
    rlang::abort(
      c(
        "La versión de Python no es compatible.",
        "x" = paste("Versión detectada:", version),
        "i" = "similR requiere Python 3.10 o superior."
      ),
      class = "similR_python_version_incompatible"
    )
  }

  .embedding_state$module <- result$module
  .embedding_state$numpy <- result$numpy

  if (isTRUE(record)) {
    probe <- list(
      python_path = result$config$python,
      python_version = version,
      sentence_transformers_available = TRUE,
      numpy_available = TRUE,
      sentence_transformers_version = tryCatch(
        as.character(reticulate::py_to_r(result$module$`__version__`)),
        error = function(e) NA_character_
      ),
      numpy_version = tryCatch(
        as.character(reticulate::py_to_r(result$numpy$`__version__`)),
        error = function(e) NA_character_
      )
    )
    write_semantic_engine_manifest(probe)
  }

  result
}

#' Check the local semantic engine
#'
#' Inspects Python, the required Python modules, and the locally downloaded
#' embedding model without downloading files or initializing a new managed
#' Python environment.
#'
#' @param model_name Sentence Transformer model identifier.
#'
#' @return An object of class `similR_semantic_status`.
#' @export
check_semantic_engine <- function(
    model_name = package_config()$default_model) {
  ensure_scalar_character(model_name, "model_name")
  probe <- probe_available_python()
  model_path <- semantic_model_dir(model_name, create_parent = FALSE)
  model_downloaded <- semantic_model_downloaded(model_name)
  model_manifest <- read_semantic_model_manifest(model_name)

  status <- structure(
    list(
      python_available = !is.null(probe),
      python_version = if (is.null(probe)) NA_character_ else probe$python_version,
      python_path = if (is.null(probe)) NA_character_ else probe$python_path,
      python_version_supported = if (is.null(probe)) FALSE else python_version_supported(probe$python_version),
      sentence_transformers_available = if (is.null(probe)) FALSE else isTRUE(probe$sentence_transformers_available),
      sentence_transformers_version = if (is.null(probe)) NA_character_ else probe$sentence_transformers_version %||% NA_character_,
      numpy_available = if (is.null(probe)) FALSE else isTRUE(probe$numpy_available),
      numpy_version = if (is.null(probe)) NA_character_ else probe$numpy_version %||% NA_character_,
      model_downloaded = model_downloaded,
      model_name = model_name,
      model_path = if (model_downloaded) fs::path_abs(model_path) else model_path,
      model_dimensions = model_manifest$embedding_dimensions %||% NA_integer_,
      model_size_bytes = semantic_model_size(model_name),
      model_size = format_bytes(semantic_model_size(model_name)),
      ready = !is.null(probe) &&
        python_version_supported(probe$python_version) &&
        isTRUE(probe$sentence_transformers_available) &&
        isTRUE(probe$numpy_available) &&
        model_downloaded
    ),
    class = "similR_semantic_status"
  )
  status
}

#' @export
print.similR_semantic_status <- function(x, ...) {
  cat("Motor semántico de similR\n")
  cat("  Python disponible:       ", if (isTRUE(x$python_available)) "sí" else "no", "\n", sep = "")
  cat("  Versión de Python:       ", x$python_version %||% NA_character_, "\n", sep = "")
  cat("  sentence-transformers:   ", if (isTRUE(x$sentence_transformers_available)) "sí" else "no", "\n", sep = "")
  cat("  NumPy:                   ", if (isTRUE(x$numpy_available)) "sí" else "no", "\n", sep = "")
  cat("  Modelo:                  ", x$model_name, "\n", sep = "")
  cat("  Modelo descargado:       ", if (isTRUE(x$model_downloaded)) "sí" else "no", "\n", sep = "")
  cat("  Listo para consultas:    ", if (isTRUE(x$ready)) "sí" else "no", "\n", sep = "")
  invisible(x)
}

#' Install or prepare the local semantic engine
#'
#' Declares and initializes an isolated Python environment through
#' `reticulate::py_require()`. This function installs Python packages when
#' required but does not download the embedding model.
#'
#' @param model_name Model that will be used after installation. It is recorded
#'   for status reporting but is not downloaded by this function.
#'
#' @return Invisibly, a `similR_semantic_status` object.
#' @export
install_semantic_engine <- function(
    model_name = package_config()$default_model) {
  ensure_scalar_character(model_name, "model_name")
  cli::cli_alert_info(
    "Se preparará Python {package_config()$python_version} con sentence-transformers y NumPy."
  )
  initialize_semantic_runtime(record = TRUE)
  status <- check_semantic_engine(model_name)
  cli::cli_alert_success("El entorno Python del motor semántico está disponible.")
  if (!status$model_downloaded) {
    cli::cli_alert_info(
      "El modelo todavía no está descargado. Ejecute `download_embedding_model()` cuando corresponda."
    )
  }
  invisible(status)
}

model_embedding_dimension <- function(model) {
  value <- if (reticulate::py_has_attr(model, "get_sentence_embedding_dimension")) {
    model$get_sentence_embedding_dimension()
  } else if (reticulate::py_has_attr(model, "get_embedding_dimension")) {
    model$get_embedding_dimension()
  } else {
    NA_integer_
  }
  if (reticulate::is_py_object(value)) {
    value <- reticulate::py_to_r(value)
  }
  as.integer(value)
}

reset_embedding_model <- function() {
  .embedding_state$model <- NULL
  .embedding_state$model_name <- NULL
  .embedding_state$model_path <- NULL
  invisible(TRUE)
}

#' Download a local embedding model
#'
#' Downloads a Sentence Transformer model only after explicit invocation and
#' stores a self-contained copy in the user cache directory.
#'
#' @param model_name Sentence Transformer model identifier.
#' @param force Replace an existing local copy and skip interactive confirmation.
#'
#' @return Invisibly, a `similR_semantic_status` object.
#' @export
#' @examples
#' \dontrun{
#' install_semantic_engine()
#' download_embedding_model()
#' }
download_embedding_model <- function(
    model_name = package_config()$default_model,
    force = FALSE) {
  ensure_scalar_character(model_name, "model_name")
  if (!is.logical(force) || length(force) != 1L || is.na(force)) {
    rlang::abort("`force` debe ser TRUE o FALSE.")
  }

  target <- semantic_model_dir(model_name)
  if (semantic_model_downloaded(model_name) && !isTRUE(force)) {
    cli::cli_alert_info("El modelo `{model_name}` ya está descargado.")
    return(invisible(check_semantic_engine(model_name)))
  }

  if (!isTRUE(force)) {
    if (!interactive()) {
      rlang::abort(
        "Use `download_embedding_model(force = TRUE)` en una sesión no interactiva.",
        class = "similR_confirmation_required"
      )
    }
    answer <- utils::askYesNo(
      paste0(
        "El modelo puede ocupar varios cientos de MB y se descargará en ",
        target, ". ¿Continuar?"
      ),
      default = FALSE
    )
    if (!isTRUE(answer)) {
      cli::cli_alert_info("Descarga cancelada.")
      return(invisible(check_semantic_engine(model_name)))
    }
  }

  runtime <- initialize_semantic_runtime(record = TRUE)
  models_root <- semantic_models_dir()
  staging <- tempfile(
    pattern = paste0(".model-", semantic_model_slug(model_name), "-"),
    tmpdir = models_root
  )
  download_cache <- fs::path(
    semantic_download_cache_dir(),
    paste0(semantic_model_slug(model_name), "-", timestamp_tag())
  )
  fs::dir_create(staging, recurse = TRUE)
  fs::dir_create(download_cache, recurse = TRUE)
  backup <- paste0(target, ".bak-", timestamp_tag(), "-", Sys.getpid())
  installed <- FALSE

  on.exit({
    if (dir.exists(download_cache)) fs::dir_delete(download_cache)
    if (!installed && dir.exists(staging)) fs::dir_delete(staging)
  }, add = TRUE)

  cli::cli_alert_info("Descargando el modelo `{model_name}`.")
  model <- tryCatch(
    runtime$module$SentenceTransformer(
      model_name_or_path = model_name,
      cache_folder = download_cache,
      trust_remote_code = FALSE
    ),
    error = function(e) {
      rlang::abort(
        c(
          "No fue posible descargar el modelo de embeddings.",
          "x" = conditionMessage(e),
          "i" = "Compruebe la conexión a internet y el espacio disponible."
        ),
        class = "similR_model_download_error",
        parent = e
      )
    }
  )

  tryCatch(
    model$save_pretrained(
      path = staging,
      model_name = model_name,
      create_model_card = TRUE,
      safe_serialization = TRUE
    ),
    error = function(e) {
      rlang::abort(
        c("No fue posible guardar la copia local del modelo.", "x" = conditionMessage(e)),
        class = "similR_model_save_error",
        parent = e
      )
    }
  )

  dimension <- model_embedding_dimension(model)
  atomic_write_json(
    list(
      model_name = model_name,
      downloaded_at = utc_now(),
      embedding_dimensions = dimension,
      normalized_by_similR = TRUE,
      query_prefix = package_config()$query_prefix,
      passage_prefix = package_config()$passage_prefix,
      sentence_transformers_version = tryCatch(
        as.character(reticulate::py_to_r(runtime$module$`__version__`)),
        error = function(e) NA_character_
      )
    ),
    fs::path(staging, "similR-model.json")
  )

  if (dir.exists(target)) rename_or_abort(target, backup)
  tryCatch(
    rename_or_abort(staging, target),
    error = function(e) {
      if (dir.exists(backup) && !dir.exists(target)) file.rename(backup, target)
      stop(e)
    }
  )
  installed <- TRUE
  if (dir.exists(backup)) fs::dir_delete(backup)

  reset_embedding_model()
  cli::cli_alert_success("El modelo `{model_name}` fue instalado localmente.")
  invisible(check_semantic_engine(model_name))
}

get_embedding_model <- function(
    model_name = package_config()$default_model) {
  ensure_scalar_character(model_name, "model_name")
  path <- semantic_model_dir(model_name, create_parent = FALSE)
  if (!semantic_model_downloaded(model_name)) {
    rlang::abort(
      c(
        "El modelo semántico no está descargado.",
        "i" = sprintf("Ejecute `download_embedding_model(%s)`.", deparse(model_name))
      ),
      class = "similR_model_not_downloaded"
    )
  }

  if (!is.null(.embedding_state$model) &&
      identical(.embedding_state$model_name, model_name) &&
      identical(.embedding_state$model_path, fs::path_abs(path))) {
    return(.embedding_state$model)
  }

  runtime <- initialize_semantic_runtime(record = TRUE)
  model <- tryCatch(
    runtime$module$SentenceTransformer(
      model_name_or_path = fs::path_abs(path),
      cache_folder = semantic_download_cache_dir(),
      local_files_only = TRUE,
      trust_remote_code = FALSE
    ),
    error = function(e) {
      rlang::abort(
        c(
          "No fue posible cargar el modelo semántico local.",
          "x" = conditionMessage(e),
          "i" = "Vuelva a ejecutar `download_embedding_model(force = TRUE)`."
        ),
        class = "similR_model_load_error",
        parent = e
      )
    }
  )

  .embedding_state$model <- model
  .embedding_state$model_name <- model_name
  .embedding_state$model_path <- fs::path_abs(path)
  model
}
