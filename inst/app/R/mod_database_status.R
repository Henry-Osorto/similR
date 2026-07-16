
mod_database_status_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::value_box(
    title = "Base bibliográfica",
    value = shiny::uiOutput(ns("value")),
    showcase = shiny::icon("database"),
    theme = "primary",
    shiny::uiOutput(ns("details"))
  )
}

mod_database_status_server <- function(id, info) {
  shiny::moduleServer(id, function(input, output, session) {
    output$value <- shiny::renderUI({
      current <- info()
      if (!isTRUE(current$installed)) return("No instalada")
      paste0(format(current$number_of_articles, big.mark = ","), " artículos")
    })
    output$details <- shiny::renderUI({
      current <- info()
      if (!isTRUE(current$installed)) return(NULL)
      shiny::tags$small(paste("Versión", current$version, "·", current$size))
    })
  })
}
