
source("global.R", local = TRUE)

ui <- bslib::page_navbar(
  title = "similR",
  id = "main_navigation",
  theme = bslib::bs_theme(version = 5, bootswatch = "flatly"),
  header = shiny::tagList(
    shiny::tags$head(
      shiny::tags$link(rel = "stylesheet", type = "text/css", href = "custom.css"),
      shiny::tags$script(shiny::HTML(paste0(
        "Shiny.addCustomMessageHandler('similR-toggle-button', function(x) {",
        "var button = document.getElementById(x.id);",
        "if (!button) return;",
        "button.disabled = x.disabled;",
        "button.innerText = x.label;",
        "});"
      )))
    )
  ),
  bslib::nav_panel(
    "Recomendar artículos",
    shiny::div(
      class = "app-container",
      shiny::div(
        class = "app-introduction",
        shiny::h1("Descubra literatura institucional relacionada"),
        shiny::p(
          "Describa su investigación y similR identificará los artículos con mayor proximidad temática, metodológica, contextual, de datos y de propósito."
        )
      ),
      bslib::layout_column_wrap(
        width = 1 / 2,
        mod_database_status_ui("database_status"),
        mod_engine_status_ui("engine_status")
      ),
      bslib::layout_sidebar(
        sidebar = bslib::sidebar(
          width = 430,
          mod_query_form_ui("query", default_engine = runtime$engine),
          open = "always"
        ),
        mod_results_table_ui("results")
      ),
      bslib::card(
        class = "responsible-use-card",
        bslib::card_header("Uso responsable"),
        shiny::tags$blockquote(
          "Las recomendaciones se basan en similitud temática, metodológica y contextual. El investigador debe revisar cada artículo y citarlo únicamente cuando contribuya de manera sustantiva a su investigación."
        ),
        shiny::tags$p(
          shiny::strong("Privacidad: "),
          "los textos introducidos se procesan localmente en la computadora del usuario y no se transmiten a servicios externos."
        )
      )
    )
  ),
  bslib::nav_panel(
    "Acerca de",
    shiny::div(
      class = "app-container about-page",
      shiny::h2("Acerca de similR"),
      shiny::p(
        "similR es una aplicación local para descubrir literatura científica institucional potencialmente relacionada con una nueva investigación."
      ),
      shiny::h4("Motores de recomendación"),
      shiny::p(
        "El motor lexical combina TF-IDF, BM25 y coincidencias exactas. El motor semántico utiliza embeddings multilingües generados con Sentence Transformers. En modo automático, similR utiliza el motor semántico únicamente cuando el entorno local y la base son compatibles."
      ),
      shiny::h4("Versión del paquete"),
      shiny::p(runtime$package_version %||% "No disponible")
    )
  )
)

server <- function(input, output, session) {
  info <- shiny::reactiveVal(similR::database_info())
  engine <- shiny::reactiveVal(runtime$engine)
  results <- shiny::reactiveVal(NULL)

  mod_database_status_server("database_status", info)
  mod_engine_status_server("engine_status", engine)
  mod_update_database_server("database_update", runtime$update_status, info)

  query_module <- mod_query_form_server("query")

  shiny::observeEvent(query_module$query(), {
    request <- query_module$query()
    query_module$set_busy(TRUE)
    on.exit(query_module$set_busy(FALSE), add = TRUE)

    result <- shiny::withProgress(message = "Comparando la investigación", value = 0, {
      shiny::incProgress(0.15, detail = "Preparando el motor de recomendación")
      tryCatch({
        recommendations <- similR::recommend_articles(
          title = request$title,
          purpose = request$purpose,
          method = request$method,
          data = request$data,
          context = request$context,
          engine = request$engine,
          n = request$n,
          weights = request$weights,
          filters = request$filters
        )
        shiny::incProgress(0.85, detail = "Ordenando recomendaciones")
        recommendations
      }, error = function(e) e)
    })

    if (inherits(result, "error")) {
      shiny::showNotification(conditionMessage(result), type = "error", duration = NULL)
    } else {
      results(result)
      selected_engine <- if (nrow(result) > 0L) {
        result$engine[[1L]]
      } else if (identical(request$engine, "auto")) {
        runtime$engine
      } else {
        request$engine
      }
      engine(selected_engine)
    }
  }, ignoreInit = TRUE)

  selected <- mod_results_table_server("results", results)
  mod_article_details_server("article_details", selected)
}

shiny::shinyApp(ui, server)
