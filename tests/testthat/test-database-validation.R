test_that("a release database validates independently", {
  directory <- withr::local_tempdir()
  release <- build_database_release(create_test_articles(), data_version = "2026.07", output_dir = directory)
  validation <- similR:::validate_database(release$database_path, release$manifest)
  expect_true(validation$valid)
  expect_equal(validation$number_of_articles, 2L)
})

test_that("missing required tables are rejected", {
  path <- tempfile(fileext = ".duckdb")
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = path)
  DBI::dbExecute(con, "CREATE TABLE articles (article_id VARCHAR)")
  DBI::dbDisconnect(con)
  expect_error(similR:::validate_database(path), class = "similR_invalid_database_schema")
})
