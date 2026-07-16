
test_that("lexical ranking returns the most related article first", {
  directory <- withr::local_tempdir()
  release <- build_database_release(
    create_test_articles(),
    data_version = "2026.07",
    output_dir = directory
  )
  withr::local_options(list(similR.cache_dir = withr::local_tempdir()))
  index <- similR:::build_lexical_index(release$database_path, use_cache = FALSE)
  query <- similR:::prepare_user_query(
    title = "Artificial intelligence literacy and entrepreneurial intention",
    purpose = "Assess entrepreneurial intention among university students",
    method = "Survey and structural equation model",
    context = "University students in Honduras"
  )
  result <- similR:::rank_articles_lexical(query, index, n = 2)
  expect_equal(nrow(result), 2L)
  expect_identical(result$rank, 1:2)
  expect_match(result$title[[1L]], "Artificial intelligence", ignore.case = TRUE)
  expect_true(all(result$index >= 0 & result$index <= 100))
  expect_true(all(diff(result$index) <= 0))
})

test_that("filters are applied before returning the top n", {
  directory <- withr::local_tempdir()
  release <- build_database_release(
    create_test_articles(),
    data_version = "2026.07",
    output_dir = directory
  )
  withr::local_options(list(similR.cache_dir = withr::local_tempdir()))
  index <- similR:::build_lexical_index(release$database_path, use_cache = FALSE)
  query <- similR:::prepare_user_query(title = "innovation")
  result <- similR:::rank_articles_lexical(
    query,
    index,
    n = 20,
    filters = list(year_min = 2026)
  )
  expect_true(all(result$year >= 2026))
})

test_that("explanations are deterministic", {
  text <- similR:::explain_recommendation(
    c(theme = 90, method = 80, context = 70)
  )
  expect_match(text, "temática")
  expect_match(text, "metodológica")
})
