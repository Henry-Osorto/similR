test_that("SHA-256 calculation and verification are reproducible", {
  path <- tempfile()
  writeLines("similR", path, useBytes = TRUE)
  hash <- similR:::sha256_file(path)
  expect_match(hash, "^[a-f0-9]{64}$")
  expect_invisible(similR:::verify_checksum(path, hash))
  expect_error(
    similR:::verify_checksum(path, paste(rep("0", 64), collapse = "")),
    class = "similR_checksum_mismatch"
  )
})

test_that("checksums.txt is parsed by file name", {
  path <- tempfile()
  hash <- paste(rep("a", 64), collapse = "")
  writeLines(paste(hash, " university_articles_2026-07.duckdb"), path)
  parsed <- similR:::parse_checksums(path)
  expect_identical(unname(parsed[["university_articles_2026-07.duckdb"]]), hash)
})
