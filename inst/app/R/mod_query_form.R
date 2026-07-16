
mod_query_form_ui <- function(id, default_engine = "lexical") {
  ns <- shiny::NS(id)
  bslib::card(
    class = "query-card",
    bslib::card_header("Descripción de la investigación"),
    shiny::textAreaInput(
      ns("title"),
      "Título de la investigación",
      rows = 2,
      placeholder = "Ej.: Alfabetización en inteligencia artificial e intención emprendedora"
    ),
    shiny::textAreaInput(
      ns("purpose"),
      "Propósito u objetivo",
      rows = 3,
      placeholder = "Describa qué pretende analizar, evaluar o explicar."
    ),
    shiny::textAreaInput(
      ns("method"),
      "Método",
      rows = 3,
      placeholder = "Ej.: encuesta transversal y modelo de ecuaciones estructurales"
    ),
    shiny::textAreaInput(
      ns("data"),
      "Datos o fuente de información",
      rows = 3,
      placeholder = "Ej.: encuesta aplicada a estudiantes universitarios"
    ),
    shiny::textAreaInput(
      ns("context"),
      "Contexto, población o ubicación",
      rows = 3,
      placeholder = "Ej.: estudiantes universitarios de Honduras"
    ),
    bslib::accordion(
      open = NULL,
      bslib::accordion_panel(
        "Opciones avanzadas",
        shiny::fluidRow(
          shiny::column(
            6,
            shiny::numericInput(
              ns("n_results"),
              "Número de resultados",
              value = 20,
              min = 1,
              max = 100,
              step = 1
            )
          ),
          shiny::column(
            6,
            shiny::selectInput(
              ns("engine"),
              "Motor",
              choices = c(
                "Automático" = "auto",
                "Lexical" = "lexical",
                "Semántico (Fase 4)" = "semantic"
              ),
              selected = default_engine
            )
          )
        ),
        shiny::tags$p(
          class = "form-hint",
          "Los pesos se renormalizan automáticamente cuando un campo está vacío."
        ),
        shiny::fluidRow(
          shiny::column(
            4,
            shiny::sliderInput(ns("weight_theme"), "Tema", min = 0, max = 1, value = 0.20, step = 0.01)
          ),
          shiny::column(
            4,
            shiny::sliderInput(ns("weight_method"), "Método", min = 0, max = 1, value = 0.22, step = 0.01)
          ),
          shiny::column(
            4,
            shiny::sliderInput(ns("weight_data"), "Datos", min = 0, max = 1, value = 0.10, step = 0.01)
          )
        ),
        shiny::fluidRow(
          shiny::column(
            4,
            shiny::sliderInput(ns("weight_context"), "Contexto", min = 0, max = 1, value = 0.23, step = 0.01)
          ),
          shiny::column(
            4,
            shiny::sliderInput(ns("weight_purpose"), "Propósito", min = 0, max = 1, value = 0.25, step = 0.01)
          ),
          shiny::column(
            4,
            shiny::actionButton(
              ns("reset_weights"),
              "Restablecer pesos",
              class = "btn-outline-secondary advanced-button"
            )
          )
        ),
        shiny::fluidRow(
          shiny::column(
            4,
            shiny::textInput(ns("year_min"), "Año mínimo", value = "", placeholder = "Ej.: 2020")
          ),
          shiny::column(
            4,
            shiny::textInput(ns("year_max"), "Año máximo", value = "", placeholder = "Ej.: 2026")
          ),
          shiny::column(
            4,
            shiny::textInput(ns("source_title"), "Revista o fuente", value = "")
          )
        )
      )
    ),
    shiny::div(
      class = "search-action",
      shiny::actionButton(
        ns("search"),
        "Buscar artículos relacionados",
        class = "btn-primary btn-lg",
        icon = shiny::icon("search")
      )
    )
  )
}

mod_query_form_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    shiny::observeEvent(input$reset_weights, {
      shiny::updateSliderInput(session, "weight_theme", value = 0.20)
      shiny::updateSliderInput(session, "weight_method", value = 0.22)
      shiny::updateSliderInput(session, "weight_data", value = 0.10)
      shiny::updateSliderInput(session, "weight_context", value = 0.23)
      shiny::updateSliderInput(session, "weight_purpose", value = 0.25)
    })

    query <- shiny::eventReactive(input$search, {
      values <- c(input$title, input$purpose, input$method, input$data, input$context)
      year_min <- if (!nzchar(trimws(input$year_min))) {
        NA_integer_
      } else {
        suppressWarnings(as.integer(input$year_min))
      }
      year_max <- if (!nzchar(trimws(input$year_max))) {
        NA_integer_
      } else {
        suppressWarnings(as.integer(input$year_max))
      }
      shiny::validate(
        shiny::need(
          any(nzchar(trimws(values))),
          "Complete al menos un campo de la investigación."
        ),
        shiny::need(
          input$n_results >= 1 && input$n_results <= 100,
          "El número de resultados debe estar entre 1 y 100."
        ),
        shiny::need(
          !nzchar(trimws(input$year_min)) || !is.na(year_min),
          "El año mínimo debe ser un número entero."
        ),
        shiny::need(
          !nzchar(trimws(input$year_max)) || !is.na(year_max),
          "El año máximo debe ser un número entero."
        ),
        shiny::need(
          is.na(year_min) || is.na(year_max) || year_min <= year_max,
          "El año mínimo no puede ser mayor que el año máximo."
        )
      )
      list(
        title = input$title,
        purpose = input$purpose,
        method = input$method,
        data = input$data,
        context = input$context,
        engine = input$engine,
        n = as.integer(input$n_results),
        weights = c(
          theme = input$weight_theme,
          method = input$weight_method,
          data = input$weight_data,
          context = input$weight_context,
          purpose = input$weight_purpose
        ),
        filters = list(
          year_min = if (is.na(year_min)) NULL else year_min,
          year_max = if (is.na(year_max)) NULL else year_max,
          source_title = input$source_title
        )
      )
    }, ignoreInit = TRUE)

    set_busy <- function(busy = TRUE) {
      session$sendCustomMessage(
        "similR-toggle-button",
        list(
          id = session$ns("search"),
          disabled = isTRUE(busy),
          label = if (isTRUE(busy)) {
            "Buscando artículos..."
          } else {
            "Buscar artículos relacionados"
          }
        )
      )
    }

    list(query = query, set_busy = set_busy)
  })
}
