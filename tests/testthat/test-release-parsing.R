test_that("release payloads are converted and identified", {
  payload <- list(
    id = 1, tag_name = "data-2026.07", published_at = "2026-07-15T00:00:00Z",
    draft = FALSE, prerelease = FALSE,
    assets = list(
      list(name = "manifest.json", browser_download_url = "https://example.org/manifest.json", url = "https://api.example.org/1", size = 100, digest = NA_character_, content_type = "application/json"),
      list(name = "checksums.txt", browser_download_url = "https://example.org/checksums.txt", url = "https://api.example.org/2", size = 100, digest = NA_character_, content_type = "text/plain"),
      list(name = "university_articles_2026-07.duckdb", browser_download_url = "https://example.org/database.duckdb", url = "https://api.example.org/3", size = 1000, digest = paste0("sha256:", paste(rep("a", 64), collapse = "")), content_type = "application/octet-stream")
    )
  )
  release <- similR:::as_release_record(payload)
  expect_true(similR:::is_data_release(release))
  expect_equal(nrow(release$assets), 3L)
})
