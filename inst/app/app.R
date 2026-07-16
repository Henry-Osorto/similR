`%||%` <- function(x, y) if (is.null(x) || length(x) == 0L) y else x

runtime <- getOption(
  "similR.runtime",
  list(engine = "lexical", update_status = list(update_available = FALSE, error = NULL), package_version = NA_character_)
)

ui <- bslib::page_fillable(
  title = "similR",
  theme = bslib::bs_theme(version = 5, bootswatch = "flatly"),
  bslib::layout_column_wrap(
    width = 1,
    bslib::card(
      bslib::card_header("similR — Fase 2"),
      shiny::h2("Base bibliográfica institucional"),
      shiny::p("Esta fase incorpora importación, limpieza, deduplicación, extracción de dimensiones y construcción reproducible de Releases DuckDB."),
      shiny::uiOutput("database_summary"),
      shiny::hr(),
      shiny::p(shiny::strong("Motor seleccionado: "), runtime$engine),
      shiny::p("El ranking lexical se incorporará en la Fase 3 y el motor semántico en la Fase 4.")
    ),
    bslib::card(
      bslib::card_header("Principio de uso responsable"),
      shiny::tags$blockquote("Las recomendaciones se basan en similitud temática, metodológica y contextual. El investigador debe revisar cada artículo y citarlo únicamente cuando contribuya de manera sustantiva a su investigación.")
    )
  )
)

server <- function(input, output, session) {
  info <- shiny::reactiveVal(similR::database_info())
  output$database_summary <- shiny::renderUI({
    current <- info()
    if (!isTRUE(current$installed)) return(shiny::div(class = "alert alert-danger", "Base no instalada."))
    shiny::tagList(
      shiny::p(shiny::strong("Versión: "), current$version),
      shiny::p(shiny::strong("Artículos: "), format(current$number_of_articles, big.mark = ",")),
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
        shiny::p(shiny::strong("Versión instalada: "), if (is.null(status$installed_version) || is.na(status$installed_version)) "No instalada" else status$installed_version),
        shiny::p(shiny::strong("Versión disponible: "), status$available_version),
        shiny::p(shiny::strong("Artículos en la nueva base: "), format(manifest$number_of_articles, big.mark = ",")),
        shiny::p(shiny::strong("Fecha de publicación: "), manifest$published_at),
        footer = shiny::tagList(shiny::modalButton("Continuar con versión instalada"), shiny::actionButton("update_now", "Actualizar ahora", class = "btn-primary")),
        easyClose = FALSE
      ))
    } else if (!is.null(status$error) && nzchar(status$error)) {
      shiny::showNotification(paste("No fue posible comprobar actualizaciones:", status$error), type = "warning", duration = 8)
    }
  }, once = TRUE)
  shiny::observeEvent(input$update_now, {
    shiny::withProgress(message = "Actualizando la base", value = 0, {
      result <- tryCatch({
        shiny::incProgress(0.2, detail = "Descargando y verificando")
        similR::update_database(force = TRUE, quiet = TRUE)
      }, error = function(e) e)
      if (inherits(result, "error")) {
        shiny::showNotification(conditionMessage(result), type = "error", duration = NULL)
      } else {
        shiny::incProgress(0.8, detail = "Actualización completada")
        info(similR::database_info())
        shiny::removeModal()
        shiny::showNotification("La base bibliográfica fue actualizada.", type = "message")
      }
    })
  })
}

shiny::shinyApp(ui, server)
