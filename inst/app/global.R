
`%||%` <- function(x, y) if (is.null(x) || length(x) == 0L) y else x

runtime <- getOption(
  "similR.runtime",
  list(
    engine = "lexical",
    update_status = list(update_available = FALSE, error = NULL),
    package_version = NA_character_
  )
)

app_root <- tryCatch(
  dirname(normalizePath(sys.frame(1)$ofile, winslash = "/", mustWork = TRUE)),
  error = function(e) normalizePath(".", winslash = "/", mustWork = TRUE)
)

module_files <- list.files(
  file.path(app_root, "R"),
  pattern = "\\.R$",
  full.names = TRUE
)
invisible(lapply(module_files, source, local = FALSE))
