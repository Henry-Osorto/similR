mod_engine_status_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::value_box(
    title = "Motor activo",
    value = shiny::uiOutput(ns("value")),
    showcase = shiny::icon("gears"),
    theme = "success",
    shiny::uiOutput(ns("details"))
  )
}

mod_engine_status_server <- function(id, engine) {
  shiny::moduleServer(id, function(input, output, session) {
    output$value <- shiny::renderUI({
      if (identical(engine(), "lexical")) "Lexical" else "Semántico"
    })
    output$details <- shiny::renderUI({
      if (identical(engine(), "lexical")) {
        shiny::tags$small("TF-IDF + BM25 + términos exactos")
      } else {
        shiny::tags$small("Embeddings multilingües procesados localmente")
      }
    })
  })
}
