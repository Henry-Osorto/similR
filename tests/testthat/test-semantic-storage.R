test_that("a complete semantic release passes compatibility checks", {
  release <- create_test_semantic_release(withr::local_tempdir())
  expect_identical(release$manifest$embedding_status, "complete")
  expect_equal(release$manifest$embedding_dimensions, 4L)
  expect_true(release$manifest$embedding_normalized)

  metadata <- similR:::validate_semantic_database_compatibility(
    release$database_path
  )
  expect_identical(metadata$status, "complete")
  expect_equal(metadata$dimensions, 4L)
})

test_that("embedding matrices preserve the requested article order", {
  articles <- create_test_articles()
  release <- create_test_semantic_release(
    withr::local_tempdir(),
    articles = articles
  )
  order <- rev(articles$article_id)
  matrix <- similR:::load_embedding_matrix(
    database_path = release$database_path,
    dimension = "theme",
    article_ids = order,
    expected_model = "intfloat/multilingual-e5-base",
    expected_dimensions = 4L
  )
  expect_equal(rownames(matrix), order)
  expect_equal(nrow(matrix), length(order))
  expect_equal(rowSums(matrix^2), rep(1, length(order)))
})

test_that("a lexical-only release is rejected by semantic compatibility", {
  release <- build_database_release(
    create_test_articles(),
    data_version = "2026.07",
    output_dir = withr::local_tempdir()
  )
  expect_error(
    similR:::validate_semantic_database_compatibility(release$database_path),
    class = "similR_semantic_database_incompatible"
  )
})

test_that("semantic index is cached in memory for the active database", {
  release <- create_test_semantic_release(withr::local_tempdir())
  similR:::clear_semantic_memory_cache()
  first <- similR:::load_semantic_index(release$database_path)
  second <- similR:::load_semantic_index(release$database_path)
  expect_s3_class(first, "similR_semantic_index")
  expect_identical(first, second)
  expect_equal(names(first$dimensions), similR:::package_config()$dimensions)
})
