
select_engine <- function(engine = c("auto", "semantic", "lexical")) {
  engine <- match.arg(engine)
  if (identical(engine, "semantic")) {
    rlang::abort(
      c(
        "El motor semántico se incorporará en la Fase 4.",
        "i" = "Use temporalmente `engine = \"lexical\"` o `engine = \"auto\"`."
      ),
      class = "similR_semantic_engine_unavailable"
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
#' @param engine Recommendation engine.
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
  engine <- select_engine(engine)
  local_status <- tryCatch(database_info(), error = function(e) NULL)
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
  app_dir <- system.file("app", package = .similr_package_name)
  if (!nzchar(app_dir) || !dir.exists(app_dir)) {
    rlang::abort(
      "No se encontró la aplicación Shiny incluida en el paquete.",
      class = "similR_app_not_found"
    )
  }
  old_options <- options(similR.runtime = list(
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
