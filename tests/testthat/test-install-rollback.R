test_that("failed manifest installation restores an existing database", {
  root <- withr::local_tempdir()
  withr::local_options(list(similR.data_dir = root))
  database_name <- "university_articles_2026-07.duckdb"
  existing <- file.path(root, database_name)
  writeLines("old database", existing)
  staged_dir <- file.path(root, ".staging-test")
  dir.create(staged_dir)
  staged <- file.path(staged_dir, database_name)
  writeLines("new database", staged)
  hash <- similR:::sha256_file(staged)
  manifest <- create_test_manifest(database_name, hash)
  bundle <- structure(
    list(
      staging_dir = staged_dir, database_path = staged,
      manifest_path = file.path(staged_dir, "manifest.json"),
      checksum_path = file.path(staged_dir, "checksums.txt"),
      manifest = manifest, validation = list(valid = TRUE), release = list()
    ),
    class = "similR_release_bundle"
  )
  failing_writer <- function(manifest) stop("manifest failure")
  expect_error(similR:::install_release_bundle(bundle, manifest_writer = failing_writer), "manifest failure")
  expect_identical(readLines(existing), "old database")
})
