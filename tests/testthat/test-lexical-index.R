
test_that("lexical index contains one aligned matrix per dimension", {
  directory <- withr::local_tempdir()
  release <- build_database_release(
    create_test_articles(),
    data_version = "2026.07",
    output_dir = directory
  )
  cache <- withr::local_tempdir()
  withr::local_options(list(similR.cache_dir = cache))
  index <- similR:::build_lexical_index(release$database_path, use_cache = FALSE)
  expect_s3_class(index, "similR_lexical_index")
  expect_identical(
    names(index$dimensions),
    c("theme", "purpose", "method", "data", "context")
  )
  expect_equal(nrow(index$dimensions$theme$counts), 2L)
  expect_identical(index$dimensions$theme$article_id, index$articles$article_id)
})

test_that("lexical index can be reused from disk cache", {
  directory <- withr::local_tempdir()
  release <- build_database_release(
    create_test_articles(),
    data_version = "2026.07",
    output_dir = directory
  )
  withr::local_options(list(similR.cache_dir = withr::local_tempdir()))
  first <- similR:::build_lexical_index(release$database_path, use_cache = TRUE)
  similR:::clear_lexical_memory_cache()
  second <- similR:::build_lexical_index(release$database_path, use_cache = TRUE)
  expect_identical(first$key, second$key)
})
