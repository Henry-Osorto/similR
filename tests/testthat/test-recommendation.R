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

test_that("automatic engine falls back to lexical when semantic is unavailable", {
  testthat::local_mocked_bindings(
    semantic_availability = function(...) {
      list(
        ready = FALSE,
        model_name = "intfloat/multilingual-e5-base",
        engine = mock_semantic_status(FALSE),
        database_ready = FALSE,
        metadata = NULL
      )
    },
    .package = "similR"
  )
  expect_identical(
    similR:::select_engine("auto", database_path = tempfile(), notify = FALSE),
    "lexical"
  )
  expect_error(
    similR:::select_engine("semantic", database_path = tempfile(), notify = FALSE),
    class = "similR_semantic_engine_unavailable"
  )
})

test_that("automatic engine selects semantic when all components are ready", {
  testthat::local_mocked_bindings(
    semantic_availability = function(...) {
      list(
        ready = TRUE,
        model_name = "intfloat/multilingual-e5-base",
        engine = mock_semantic_status(TRUE),
        database_ready = TRUE,
        metadata = list()
      )
    },
    .package = "similR"
  )
  expect_identical(
    similR:::select_engine("auto", database_path = tempfile(), notify = FALSE),
    "semantic"
  )
})
