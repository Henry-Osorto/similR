test_that("article embedding generation creates five vectors per article", {
  articles <- create_test_articles()
  testthat::local_mocked_bindings(
    embed_texts = function(texts, type, model_name, batch_size = 32L) {
      output <- matrix(0, nrow = length(texts), ncol = 4L)
      output[, 1L] <- 1
      output
    },
    .package = "similR"
  )
  result <- generate_article_embeddings(articles)
  expect_equal(nrow(result), nrow(articles) * 5L)
  expect_setequal(unique(result$dimension), similR:::package_config()$dimensions)
  expect_true(all(lengths(result$embedding) == 4L))
  expect_true(all(result$normalized))
})

test_that("compatible unchanged articles are not regenerated", {
  articles <- create_test_articles()
  release <- create_test_semantic_release(
    withr::local_tempdir(),
    articles = articles
  )
  testthat::local_mocked_bindings(
    embed_texts = function(...) stop("should not be called"),
    .package = "similR"
  )
  result <- generate_article_embeddings(
    articles,
    previous_database = release$database_path
  )
  expect_equal(nrow(result), 0L)
  expect_equal(attr(result, "generation_summary")$generated_articles, 0L)
})
