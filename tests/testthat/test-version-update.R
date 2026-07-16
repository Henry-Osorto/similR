test_that("data versions compare in the expected direction", {
  expect_equal(similR:::compare_data_versions("2026.04", "2026.07"), 1L)
  expect_equal(similR:::compare_data_versions("2026.07", "2026.07"), 0L)
  expect_equal(similR:::compare_data_versions("2026.08", "2026.07"), -1L)
  expect_equal(similR:::compare_data_versions(NA_character_, "2026.07"), 1L)
})

test_that("offline update checks preserve local availability", {
  root <- withr::local_tempdir()
  withr::local_options(list(similR.data_dir = root))
  local_mocked_bindings(github_latest_release = function() stop("offline"), .package = "similR")
  result <- check_database_update()
  expect_false(result$update_available)
  expect_match(result$error, "offline")
})
