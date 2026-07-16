test_that("DOIs and names are normalized", {
  raw <- tibble::tibble(
    `Document Title` = "  Análisis de innovación  ",
    Authors = "Ana Pérez | Juan López",
    Abstract = " Resumen del estudio. ",
    `Author Keywords` = "Innovación, Empresas",
    `Index Keywords` = "innovation; firms",
    DOI = " https://doi.org/10.1234/ABC.99 ",
    Year = "2025",
    `Source title` = "Journal"
  )
  result <- process_scopus(raw, source = "scopus")
  expect_identical(result$doi_normalized[[1]], "10.1234/abc.99")
  expect_identical(result$title[[1]], "Análisis de innovación")
  expect_match(result$authors[[1]], ";")
  expect_match(result$article_id[[1]], "^[a-f0-9]{64}$")
  expect_match(result$content_hash[[1]], "^[a-f0-9]{64}$")
})

test_that("duplicate DOI and title-year records are consolidated", {
  raw <- tibble::tibble(
    Title = c("Same title", "Same title", "Same title"),
    Authors = c("A", "A; B", "A"),
    Abstract = c("Short", "A considerably longer abstract", "Another abstract"),
    Keywords = c("one", "two", "three"),
    DOI = c("10.1000/a", "https://doi.org/10.1000/A", ""),
    Year = c(2024, 2024, 2024)
  )
  result <- process_scopus(raw, source = "generic")
  expect_equal(nrow(result), 1L)
  expect_match(result$keywords[[1]], "one|two|three")
  report <- attr(result, "duplicate_report")
  expect_true(sum(report$removed_rows) >= 2L)
})

test_that("stable identifiers do not depend on row order", {
  raw <- tibble::tibble(
    Title = c("First", "Second"), Authors = c("A", "B"),
    Abstract = c("x", "y"), DOI = c("10.1000/1", ""), Year = c(2025, 2024)
  )
  a <- process_scopus(raw, source = "generic")
  b <- process_scopus(raw[2:1, ], source = "generic")
  expect_setequal(a$article_id, b$article_id)
})
