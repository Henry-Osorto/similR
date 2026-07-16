#' Calculate a file SHA-256 checksum
#' @noRd
sha256_file <- function(path) {
  if (!file.exists(path)) {
    rlang::abort(
      sprintf("No existe el archivo `%s`.", path),
      class = "similR_file_not_found"
    )
  }

  tolower(digest::digest(
    object = path,
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  ))
}

#' Parse a standard checksums file
#' @noRd
parse_checksums <- function(path) {
  if (!file.exists(path)) {
    rlang::abort(
      sprintf("No existe el archivo de checksums `%s`.", path),
      class = "similR_checksum_file_not_found"
    )
  }

  lines <- trimws(readLines(path, warn = FALSE, encoding = "UTF-8"))
  lines <- lines[nzchar(lines) & !startsWith(lines, "#")]

  if (length(lines) == 0L) {
    rlang::abort(
      "El archivo de checksums está vacío.",
      class = "similR_invalid_checksum_file"
    )
  }

  pattern <- "^([A-Fa-f0-9]{64})\\s+\\*?(.+)$"
  matches <- regexec(pattern, lines, perl = TRUE)
  parsed <- regmatches(lines, matches)
  valid <- lengths(parsed) == 3L

  if (!all(valid)) {
    rlang::abort(
      "El archivo de checksums contiene líneas con formato inválido.",
      class = "similR_invalid_checksum_file"
    )
  }

  hashes <- vapply(parsed, `[[`, character(1), 2L)
  names(hashes) <- basename(vapply(parsed, `[[`, character(1), 3L))
  tolower(hashes)
}

#' Verify a file checksum
#' @noRd
verify_checksum <- function(path, expected) {
  ensure_scalar_character(expected, "expected")
  expected <- tolower(sub("^sha256:", "", trimws(expected)))

  if (!grepl("^[a-f0-9]{64}$", expected)) {
    rlang::abort(
      "El checksum esperado no es un SHA-256 válido.",
      class = "similR_invalid_checksum"
    )
  }

  actual <- sha256_file(path)
  if (!identical(actual, expected)) {
    rlang::abort(
      c(
        "La verificación SHA-256 falló.",
        "x" = paste("Esperado:", expected),
        "x" = paste("Calculado:", actual)
      ),
      class = "similR_checksum_mismatch",
      expected = expected,
      actual = actual
    )
  }

  invisible(TRUE)
}
