
default_similarity_weights <- function() {
  c(
    theme = 0.20,
    method = 0.22,
    data = 0.10,
    context = 0.23,
    purpose = 0.25
  )
}

validate_query_text <- function(x, field, max_characters = 20000L) {
  if (is.null(x) || length(x) == 0L || is.na(x[[1L]])) return("")
  if (!is.character(x) || length(x) != 1L) {
    rlang::abort(sprintf("`%s` debe ser una cadena de caracteres.", field))
  }
  value <- normalize_text(x)
  if (nchar(value, type = "chars") > max_characters) {
    rlang::abort(
      sprintf("`%s` excede el límite de %s caracteres.", field, format(max_characters, big.mark = ",")),
      class = "similR_query_too_long"
    )
  }
  value
}

prepare_user_query <- function(
    title = NULL,
    purpose = NULL,
    method = NULL,
    data = NULL,
    context = NULL) {
  query <- c(
    theme = validate_query_text(title, "title"),
    purpose = validate_query_text(purpose, "purpose"),
    method = validate_query_text(method, "method"),
    data = validate_query_text(data, "data"),
    context = validate_query_text(context, "context")
  )
  available <- nzchar(trimws(query))
  if (!any(available)) {
    rlang::abort(
      c(
        "Debe proporcionar al menos un campo de investigación.",
        "i" = "Se recomienda completar como mínimo el título o el propósito."
      ),
      class = "similR_empty_query"
    )
  }
  structure(query, available_dimensions = names(query)[available])
}

normalize_weights <- function(weights = NULL, available_dimensions) {
  dimensions <- package_config()$dimensions
  defaults <- default_similarity_weights()
  defaults <- defaults[dimensions]

  if (is.logical(available_dimensions) && !is.null(names(available_dimensions))) {
    available_dimensions <- names(available_dimensions)[available_dimensions]
  }
  available_dimensions <- intersect(as.character(available_dimensions), dimensions)
  if (length(available_dimensions) == 0L) {
    rlang::abort("No hay dimensiones disponibles para normalizar los pesos.")
  }

  effective <- defaults
  if (!is.null(weights)) {
    if (!is.numeric(weights) || any(!is.finite(weights)) || any(weights < 0)) {
      rlang::abort("`weights` debe contener valores numéricos finitos y no negativos.")
    }
    if (is.null(names(weights))) {
      if (length(weights) != length(dimensions)) {
        rlang::abort("Un vector de pesos sin nombres debe contener cinco valores.")
      }
      names(weights) <- dimensions
    }
    unknown <- setdiff(names(weights), dimensions)
    if (length(unknown) > 0L) {
      rlang::abort(paste("Dimensiones desconocidas en `weights`:", paste(unknown, collapse = ", ")))
    }
    effective[names(weights)] <- weights
  }

  effective[setdiff(dimensions, available_dimensions)] <- 0
  total <- sum(effective)
  if (!is.finite(total) || total <= 0) {
    rlang::abort("La suma de los pesos disponibles debe ser mayor que cero.")
  }
  effective / total
}
