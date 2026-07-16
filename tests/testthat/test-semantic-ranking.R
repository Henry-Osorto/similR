test_that("semantic ranking orders the closest normalized vector first", {
  articles <- create_test_articles()
  release <- create_test_semantic_release(
    withr::local_tempdir(),
    articles = articles
  )
  testthat::local_mocked_bindings(
    embed_texts = function(texts, type, model_name, batch_size = 32L) {
      matrix(c(1, 0, 0, 0), nrow = 1L)
    },
    .package = "similR"
  )

  query <- similR:::prepare_user_query(
    title = "Artificial intelligence and entrepreneurship"
  )
  result <- similR:::rank_articles_semantic(
    query = query,
    database_path = release$database_path,
    n = 2L
  )
  expect_s3_class(result, "tbl_df")
  expect_equal(result$article_id[[1L]], articles$article_id[[1L]])
  expect_identical(result$engine[[1L]], "semantic")
  expect_true(all(result$index >= 0 & result$index <= 100))
})

test_that("cosine conversion is bounded between zero and one", {
  expect_equal(
    similR:::semantic_cosine_to_unit(c(-2, -1, 0, 1, 2, NA)),
    c(0, 0, 0.5, 1, 1, 0)
  )
})
