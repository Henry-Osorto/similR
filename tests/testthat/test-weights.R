
test_that("weights are renormalized over available dimensions", {
  weights <- similR:::normalize_weights(
    available_dimensions = c("theme", "method", "context")
  )
  expect_equal(sum(weights), 1)
  expect_equal(weights[["purpose"]], 0)
  expect_equal(weights[["data"]], 0)
  expect_gt(weights[["context"]], weights[["theme"]])
})

test_that("custom weights are accepted and normalized", {
  weights <- similR:::normalize_weights(
    weights = c(theme = 2, method = 1, context = 1),
    available_dimensions = c("theme", "method", "context")
  )
  expect_equal(weights[["theme"]], 0.5)
  expect_equal(sum(weights), 1)
})

test_that("invalid weights are rejected", {
  expect_error(
    similR:::normalize_weights(c(theme = -1), "theme")
  )
})
