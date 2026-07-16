
test_that("recommend_articles uses the installed local lexical database", {
  release_dir <- withr::local_tempdir()
  release <- build_database_release(
    create_test_articles(),
    data_version = "2026.07",
    output_dir = release_dir
  )
  data_dir <- withr::local_tempdir()
  cache_dir <- withr::local_tempdir()
  install_test_release(release, data_dir)
  withr::local_options(list(
    similR.data_dir = data_dir,
    similR.cache_dir = cache_dir
  ))
  result <- recommend_articles(
    title = "Artificial intelligence literacy and entrepreneurship",
    method = "Structural equation model",
    context = "University students in Honduras",
    engine = "lexical",
    n = 1
  )
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1L)
  expect_match(result$title[[1L]], "Artificial intelligence", ignore.case = TRUE)
})

test_that("automatic engine falls back to lexical in Phase 3", {
  expect_identical(similR:::select_engine("auto"), "lexical")
  expect_error(
    similR:::select_engine("semantic"),
    class = "similR_semantic_engine_unavailable"
  )
})
