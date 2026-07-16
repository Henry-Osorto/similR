
mod_article_details_server <- function(id, selected_article) {
  shiny::moduleServer(id, function(input, output, session) {
    shiny::observeEvent(selected_article(), {
      article <- selected_article()
      if (is.null(article) || nrow(article) == 0L) return()
      doi_ui <- if (nzchar(article$doi[[1L]])) {
        shiny::tags$a(
          href = paste0("https://doi.org/", article$doi[[1L]]),
          target = "_blank",
          rel = "noopener noreferrer",
          article$doi[[1L]]
        )
      } else {
        "No disponible"
      }
      shiny::showModal(shiny::modalDialog(
        title = article$title[[1L]],
        size = "l",
        shiny::tags$dl(
          shiny::tags$dt("Autores"), shiny::tags$dd(article$authors[[1L]]),
          shiny::tags$dt("Año"), shiny::tags$dd(article$year[[1L]] %||% "No disponible"),
          shiny::tags$dt("Fuente"), shiny::tags$dd(article$source_title[[1L]] %||% "No disponible"),
          shiny::tags$dt("DOI"), shiny::tags$dd(doi_ui),
          shiny::tags$dt("Palabras clave"), shiny::tags$dd(article$keywords[[1L]] %||% "No disponibles")
        ),
        shiny::h5("Resumen"),
        shiny::p(article$abstract[[1L]] %||% "No disponible"),
        shiny::h5("Razón de la recomendación"),
        shiny::p(article$explanation[[1L]]),
        shiny::fluidRow(
          shiny::column(
            4,
            shiny::strong("Índice general"),
            shiny::p(sprintf("%.1f", article$index[[1L]]))
          ),
          shiny::column(
            4,
            shiny::strong("Tema"),
            shiny::p(format_score(article$similarity_theme[[1L]]))
          ),
          shiny::column(
            4,
            shiny::strong("Método"),
            shiny::p(format_score(article$similarity_method[[1L]]))
          )
        ),
        footer = shiny::modalButton("Cerrar"),
        easyClose = TRUE
      ))
    }, ignoreInit = TRUE)
  })
}
