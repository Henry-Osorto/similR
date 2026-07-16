sentence_transformers <- NULL

# The package must load without initializing Python and without network access.
.onLoad <- function(libname, pkgname) {
  reticulate::py_require(
    packages = package_config()$python_packages,
    python_version = package_config()$python_version
  )

  sentence_transformers <<- reticulate::import(
    "sentence_transformers",
    delay_load = TRUE
  )

  invisible(NULL)
}
