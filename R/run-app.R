semantic_availability <- function(
    database_path = local_database_path(must_exist = TRUE)) {
  metadata <- tryCatch(
    semantic_database_metadata(database_path),
    error = function(e) NULL
  )
  model_name <- if (is.null(metadata) || is_blank_string(metadata$model_name)) {
    package_config()$default_model
  } else {
    metadata$model_name
  }
  engine_status <- check_semantic_engine(model_name)
  database_ready <- semantic_database_ready(database_path, model_name)
  list(
    ready = isTRUE(engine_status$ready) && isTRUE(database_ready),
    model_name = model_name,
    engine = engine_status,
    database_ready = database_ready,
    metadata = metadata
  )
}

semantic_unavailable_message <- function(availability) {
  problems <- character()
  if (!isTRUE(availability$engine$python_available)) {
    problems <- c(problems, "Python no está configurado")
  } else {
    if (!isTRUE(availability$engine$python_version_supported)) {
      problems <- c(problems, "Python debe ser 3.10 o superior")
    }
    if (!isTRUE(availability$engine$sentence_transformers_available)) {
      problems <- c(problems, "falta sentence-transformers")
    }
    if (!isTRUE(availability$engine$numpy_available)) {
      problems <- c(problems, "falta NumPy")
    }
  }
  if (!isTRUE(availability$engine$model_downloaded)) {
    problems <- c(problems, paste0("no está descargado el modelo ", availability$model_name))
  }
  if (!isTRUE(availability$database_ready)) {
    problems <- c(problems, "la base no contiene embeddings completos y compatibles")
  }
  if (length(problems) == 0L) problems <- "el motor no superó la comprobación de disponibilidad"
  problems
}

select_engine <- function(
    engine = c("auto", "semantic", "lexical"),
    database_path = local_database_path(must_exist = TRUE),
    notify = interactive()) {
  engine <- match.arg(engine)
  if (identical(engine, "lexical")) return("lexical")

  availability <- semantic_availability(database_path)
  if (identical(engine, "semantic")) {
    if (!isTRUE(availability$ready)) {
      rlang::abort(
        c(
          "El motor semántico no está disponible.",
          "x" = paste(semantic_unavailable_message(availability), collapse = "; "),
          "i" = "Ejecute `install_semantic_engine()` y `download_embedding_model()`.",
          "i" = "La Release debe construirse con embeddings completos del mismo modelo."
        ),
        class = "similR_semantic_engine_unavailable"
      )
    }
    return("semantic")
  }

  if (isTRUE(availability$ready)) return("semantic")
  if (isTRUE(notify) && !isTRUE(.embedding_state$fallback_notified)) {
    cli::cli_inform(c(
      "i" = "El motor semántico no está disponible; se utilizará el motor lexical.",
      "i" = "Para habilitarlo, ejecute `install_semantic_engine()` y `download_embedding_model()`."
    ))
    .embedding_state$fallback_notified <- TRUE
  }
  "lexical"
}

confirm_initial_download <- function() {
  if (!interactive()) {
    rlang::abort(
      c(
        "La base bibliográfica todavía no está instalada.",
        "i" = "Ejecute `update_database()` antes de `run_app()`."
      ),
      class = "similR_database_not_found"
    )
  }
  answer <- utils::menu(
    c("Descargar la base ahora", "Cancelar"),
    title = "similR necesita descargar la base bibliográfica desde GitHub Releases."
  )
  identical(answer, 1L)
}

#' Run the local similR Shiny application
#'
#' @param engine Recommendation engine. In automatic mode the semantic engine
#'   is used only when Python, the local model, and compatible database
#'   embeddings are all available; otherwise the lexical engine is used.
#' @param check_updates Check GitHub Releases before opening the app.
#' @param launch.browser Passed to [shiny::runApp()].
#' @param host Local host.
#' @param port Optional local port.
#' @return The value returned by [shiny::runApp()], invisibly.
#' @export
run_app <- function(
    engine = c("auto", "semantic", "lexical"),
    check_updates = TRUE,
    launch.browser = TRUE,
    host = "127.0.0.1",
    port = NULL) {
  requested_engine <- match.arg(engine)
  local_status <- tryCatch(database_info(), error = function(e) NULL)
  if (is.null(local_status) || !isTRUE(local_status$installed)) {
    if (!confirm_initial_download()) {
      rlang::abort("La aplicación no puede iniciarse sin una base local válida.")
    }
    update_database(force = TRUE)
  }

  database_path <- local_database_path(must_exist = TRUE)
  resolved_engine <- select_engine(
    requested_engine,
    database_path = database_path,
    notify = identical(requested_engine, "auto")
  )
  update_status <- if (isTRUE(check_updates)) {
    check_database_update()
  } else {
    list(update_available = FALSE, error = NULL)
  }
  app_dir <- system.file("app", package = .similr_package_name)
  if (!nzchar(app_dir) || !dir.exists(app_dir)) {
    rlang::abort(
      "No se encontró la aplicación Shiny incluida en el paquete.",
      class = "similR_app_not_found"
    )
  }
  old_options <- options(similR.runtime = list(
    engine = resolved_engine,
    requested_engine = requested_engine,
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
