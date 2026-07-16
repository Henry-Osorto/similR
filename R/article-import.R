#' Import institutional article data
#'
#' Reads a bibliographic file into a tibble. CSV, TSV, RDS, JSON, XLS and XLSX
#' files are supported. Excel support requires the suggested package `readxl`.
#'
#' @param path Path to the source file.
#' @param sheet Excel sheet name or number. Ignored for other formats.
#' @param ... Additional arguments passed to the selected reader.
#'
#' @return A tibble containing the imported records.
#' @export
import_article_data <- function(path, sheet = 1, ...) {
  ensure_scalar_character(path, "path")
  if (!file.exists(path)) {
    rlang::abort(
      sprintf("No existe el archivo `%s`.", path),
      class = "similR_file_not_found"
    )
  }

  extension <- tolower(fs::path_ext(path))
  if (extension == "csv") {
    result <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE, ...)
  } else if (extension == "tsv") {
    result <- readr::read_tsv(path, show_col_types = FALSE, progress = FALSE, ...)
  } else if (extension == "txt") {
    result <- readr::read_delim(path, delim = "\t", show_col_types = FALSE, progress = FALSE, ...)
  } else if (extension == "rds") {
    result <- readRDS(path)
  } else if (extension == "json") {
    result <- jsonlite::fromJSON(path, flatten = TRUE, ...)
  } else if (extension %in% c("xls", "xlsx")) {
    if (!requireNamespace("readxl", quietly = TRUE)) {
      rlang::abort(
        c(
          "Para importar archivos Excel se requiere el paquete `readxl`.",
          "i" = "Instálelo con `install.packages(\"readxl\")`."
        ),
        class = "similR_missing_optional_package"
      )
    }
    result <- readxl::read_excel(path, sheet = sheet, ...)
  } else {
    rlang::abort(
      sprintf("Formato `%s` no compatible.", extension),
      class = "similR_unsupported_file_format"
    )
  }

  ensure_data_frame(result, "resultado importado")
  tibble::as_tibble(result)
}
