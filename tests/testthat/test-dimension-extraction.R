test_that("dimension rules extract purpose, method, data and context", {
  data <- create_test_articles()
  first <- data[1, ]
  expect_match(first$purpose_text, "aims", ignore.case = TRUE)
  expect_match(first$method_text, "survey|structural equation", ignore.case = TRUE)
  expect_match(first$data_text, "survey", ignore.case = TRUE)
  expect_match(first$context_text, "students|Honduras", ignore.case = TRUE)
  expect_equal(first$theme_source, "constructed")
  expect_true(all(first$purpose_confidence > 0))
})

test_that("explicit dimension fields have priority", {
  raw <- tibble::tibble(
    Title = "Article", Abstract = "No structured information.",
    Purpose = "Explicit purpose", Method = "Explicit method",
    Data = "Explicit data", Context = "Explicit context"
  )
  processed <- process_scopus(
    raw,
    column_map = c(
      title = "Title", abstract = "Abstract", purpose = "Purpose",
      method = "Method", data = "Data", context = "Context"
    )
  )
  result <- build_dimension_texts(processed)
  expect_identical(result$purpose_text[[1]], "Explicit purpose")
  expect_identical(result$purpose_source[[1]], "explicit")
  expect_equal(result$purpose_confidence[[1]], 1)
})
