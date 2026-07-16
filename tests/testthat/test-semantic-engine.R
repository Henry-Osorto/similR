test_that("semantic model paths live in the user cache", {
  cache <- withr::local_tempdir()
  withr::local_options(list(similR.cache_dir = cache))
  path <- similR:::semantic_model_dir("owner/model")
  expect_true(startsWith(path, normalizePath(cache, winslash = "/", mustWork = FALSE)))
  expect_match(basename(path), "owner--model")
})

test_that("semantic status inspection does not download a model", {
  cache <- withr::local_tempdir()
  withr::local_options(list(similR.cache_dir = cache))
  testthat::local_mocked_bindings(
    probe_available_python = function() NULL,
    .package = "similR"
  )
  status <- check_semantic_engine("owner/model")
  expect_s3_class(status, "similR_semantic_status")
  expect_false(status$python_available)
  expect_false(status$model_downloaded)
  expect_false(status$ready)
  expect_false(dir.exists(similR:::semantic_model_dir("owner/model", create_parent = FALSE)))
})

test_that("live embedding test is skipped unless local engine is ready", {
  status <- check_semantic_engine()
  testthat::skip_if_not(isTRUE(status$ready))
  vector <- similR:::embed_texts(
    "Prueba de similitud semántica",
    type = "query"
  )
  expect_true(is.matrix(vector))
  expect_equal(nrow(vector), 1L)
})
