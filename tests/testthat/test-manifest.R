test_that("a Phase 2 manifest without embeddings is valid", {
  manifest <- create_test_manifest(
    "university_articles_2026-07.duckdb",
    paste(rep("b", 64), collapse = ""),
    embedding_status = "absent"
  )
  result <- similR:::validate_manifest(manifest)
  expect_identical(result$embedding_dimensions, 0L)
  expect_identical(result$embedding_status, "absent")
  expect_false(result$embedding_normalized)
})

test_that("manifest rejects traversal and invalid hashes", {
  manifest <- create_test_manifest(
    "../university_articles_2026-07.duckdb",
    paste(rep("c", 64), collapse = "")
  )
  expect_error(similR:::validate_manifest(manifest), class = "similR_invalid_manifest")
  manifest <- create_test_manifest("university_articles_2026-07.duckdb", "invalid")
  expect_error(similR:::validate_manifest(manifest), class = "similR_invalid_manifest")
})
