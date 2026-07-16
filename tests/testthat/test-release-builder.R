test_that("a complete Phase 2 release is built and validates", {
  directory <- withr::local_tempdir()
  release <- build_database_release(
    data = create_test_articles(),
    data_version = "2026.07",
    output_dir = directory,
    overwrite = TRUE
  )
  expect_s3_class(release, "similR_release")
  expect_true(file.exists(release$database_path))
  expect_true(file.exists(release$manifest_path))
  expect_true(file.exists(release$checksums_path))
  expect_identical(release$manifest$embedding_status, "absent")
  validation <- validate_release(directory)
  expect_true(validation$valid)
  expect_equal(validation$database$number_of_articles, 2L)
})

test_that("incremental releases preserve unchanged timestamps", {
  first_dir <- file.path(withr::local_tempdir(), "first")
  second_dir <- file.path(withr::local_tempdir(), "second")
  articles <- create_test_articles()
  first <- build_database_release(articles, data_version = "2026.06", output_dir = first_dir)
  second <- build_database_release(
    articles,
    previous_database = first$database_path,
    data_version = "2026.07",
    output_dir = second_dir
  )
  expect_equal(second$comparison$summary$unchanged, 2L)
  con1 <- DBI::dbConnect(duckdb::duckdb(), first$database_path, read_only = TRUE)
  con2 <- DBI::dbConnect(duckdb::duckdb(), second$database_path, read_only = TRUE)
  on.exit(DBI::dbDisconnect(con1), add = TRUE)
  on.exit(DBI::dbDisconnect(con2), add = TRUE)
  a <- DBI::dbGetQuery(con1, "SELECT article_id, created_at, updated_at FROM articles ORDER BY article_id")
  b <- DBI::dbGetQuery(con2, "SELECT article_id, created_at, updated_at FROM articles ORDER BY article_id")
  expect_equal(a, b)
})
