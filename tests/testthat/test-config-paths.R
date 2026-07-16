test_that("configuration can be overridden centrally", {
  withr::local_options(list(
    similR.github_owner = "example-owner",
    similR.github_repo = "example-repo"
  ))
  config <- similR:::package_config()
  expect_identical(config$package_name, "similR")
  expect_identical(config$github_owner, "example-owner")
  expect_identical(config$github_repo, "example-repo")
})

test_that("data and cache paths support isolated overrides", {
  root <- withr::local_tempdir()
  data_dir <- file.path(root, "data")
  cache_dir <- file.path(root, "cache")
  withr::local_options(list(similR.data_dir = data_dir, similR.cache_dir = cache_dir))
  expect_identical(similR:::user_data_dir(), fs::path_abs(data_dir))
  expect_identical(similR:::user_cache_dir(), fs::path_abs(cache_dir))
  expect_true(dir.exists(data_dir))
  expect_true(dir.exists(cache_dir))
})
