
mod_update_database_server <- function(id, update_status, database_info_reactive) {
  shiny::moduleServer(id, function(input, output, session) {
    shiny::observeEvent(TRUE, {
      status <- update_status
      if (isTRUE(status$update_available)) {
        manifest <- status$manifest
        shiny::showModal(shiny::modalDialog(
          title = "Se encontró una nueva base bibliográfica",
          shiny::p(
            shiny::strong("Versión instalada: "),
            if (is.null(status$installed_version) || is.na(status$installed_version)) {
              "No instalada"
            } else {
              status$installed_version
            }
          ),
          shiny::p(shiny::strong("Versión disponible: "), status$available_version),
          shiny::p(
            shiny::strong("Artículos en la nueva base: "),
            format(manifest$number_of_articles, big.mark = ",")
          ),
          shiny::p(shiny::strong("Fecha de publicación: "), manifest$published_at),
          footer = shiny::tagList(
            shiny::modalButton("Continuar con versión instalada"),
            shiny::actionButton(
              session$ns("update_now"),
              "Actualizar ahora",
              class = "btn-primary"
            )
          ),
          easyClose = FALSE
        ))
      } else if (!is.null(status$error) && nzchar(status$error)) {
        shiny::showNotification(
          paste("No fue posible comprobar actualizaciones:", status$error),
          type = "warning",
          duration = 8
        )
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
          database_info_reactive(similR::database_info())
          shiny::removeModal()
          shiny::showNotification("La base bibliográfica fue actualizada.", type = "message")
        }
      })
    })
  })
}
