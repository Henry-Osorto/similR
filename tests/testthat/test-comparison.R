test_that("database comparison classifies all four states", {
  previous <- tibble::tibble(
    article_id = c("a", "b", "d"),
    content_hash = c("same", "old", "removed")
  )
  current <- tibble::tibble(
    article_id = c("a", "b", "c"),
    content_hash = c("same", "new", "created")
  )
  result <- compare_database_versions(current, previous)
  expect_s3_class(result, "similR_database_comparison")
  expect_equal(result$summary$unchanged, 1L)
  expect_equal(result$summary$modified, 1L)
  expect_equal(result$summary$new, 1L)
  expect_equal(result$summary$removed, 1L)
})
