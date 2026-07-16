test_that("CSV files are imported as tibbles", {
  path <- tempfile(fileext = ".csv")
  readr::write_csv(tibble::tibble(Title = "Article", DOI = "10.1000/test"), path)
  result <- import_article_data(path)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1L)
})
