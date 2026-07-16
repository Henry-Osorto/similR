# The package must load without Python and without network access.
.onLoad <- function(libname, pkgname) {
  invisible(NULL)
}
