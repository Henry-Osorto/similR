
mod_results_table_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::card(
    class = "results-card",
    bslib::card_header(
      shiny::div(
        class = "results-header",
        shiny::span("Artículos recomendados"),
        shiny::downloadButton(
          ns("download"),
          "Descargar CSV",
          class = "btn-sm btn-outline-primary"
        )
      )
    ),
    shiny::uiOutput(ns("summary")),
    DT::DTOutput(ns("table"))
  )
}

format_score <- function(x) {
  ifelse(is.na(x), "—", sprintf("%.1f", x))
}

mod_results_table_server <- function(id, results) {
  shiny::moduleServer(id, function(input, output, session) {
    output$summary <- shiny::renderUI({
      current <- results()
      if (is.null(current)) {
        return(shiny::div(
          class = "empty-results",
          "Complete el formulario para buscar artículos relacionados."
        ))
      }
      if (nrow(current) == 0L) {
        return(shiny::div(
          class = "alert alert-warning",
          "No se encontraron artículos con los filtros seleccionados."
        ))
      }
      shiny::div(
        class = "result-summary",
        shiny::strong(format(nrow(current), big.mark = ",")),
        " artículos mostrados. Seleccione una fila para consultar sus detalles."
      )
    })

    display_data <- shiny::reactive({
      current <- results()
      if (is.null(current) || nrow(current) == 0L) return(data.frame())
      doi_link <- ifelse(
        nzchar(current$doi),
        sprintf(
          '<a href="https://doi.org/%s" target="_blank" rel="noopener noreferrer">DOI</a>',
          current$doi
        ),
        ""
      )
      data.frame(
        Ranking = current$rank,
        Índice = sprintf("%.1f", current$index),
        Tema = format_score(current$similarity_theme),
        Método = format_score(current$similarity_method),
        Datos = format_score(current$similarity_data),
        Contexto = format_score(current$similarity_context),
        Propósito = format_score(current$similarity_purpose),
        Título = current$title,
        Autores = current$authors,
        Año = current$year,
        DOI = doi_link,
        check.names = FALSE
      )
    })

    output$table <- DT::renderDT({
      table_data <- display_data()
      if (nrow(table_data) == 0L) return(DT::datatable(data.frame()))
      DT::datatable(
        table_data,
        escape = FALSE,
        rownames = FALSE,
        selection = "single",
        extensions = "Scroller",
        options = list(
          pageLength = 20,
          scrollX = TRUE,
          scrollY = "620px",
          scroller = TRUE,
          deferRender = TRUE,
          columnDefs = list(
            list(className = "dt-center", targets = 0:6),
            list(width = "330px", targets = 7),
            list(width = "220px", targets = 8)
          ),
          language = list(
            search = "Buscar:",
            lengthMenu = "Mostrar _MENU_",
            info = "Mostrando _START_ a _END_ de _TOTAL_",
            infoEmpty = "Sin resultados",
            zeroRecords = "No se encontraron coincidencias",
            paginate = list(previous = "Anterior", `next` = "Siguiente")
          )
        )
      )
    })

    selected <- shiny::reactive({
      current <- results()
      row <- input$table_rows_selected
      if (is.null(current) || length(row) != 1L || row < 1L || row > nrow(current)) {
        return(NULL)
      }
      current[row, , drop = FALSE]
    })

    output$download <- shiny::downloadHandler(
      filename = function() paste0("similR-recomendaciones-", Sys.Date(), ".csv"),
      content = function(file) {
        current <- results()
        if (is.null(current)) current <- data.frame()
        utils::write.csv(current, file, row.names = FALSE, fileEncoding = "UTF-8")
      }
    )

    selected
  })
}
