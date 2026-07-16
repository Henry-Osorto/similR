
test_that("TF-IDF, BM25 and exact scores remain between zero and one", {
  directory <- withr::local_tempdir()
  release <- build_database_release(
    create_test_articles(),
    data_version = "2026.07",
    output_dir = directory
  )
  withr::local_options(list(similR.cache_dir = withr::local_tempdir()))
  index <- similR:::build_lexical_index(release$database_path, use_cache = FALSE)
  dimension <- index$dimensions$theme
  query <- "artificial intelligence entrepreneurship university students"
  scores <- list(
    tfidf = similR:::tfidf_similarity(query, dimension),
    bm25 = similR:::bm25_similarity(query, dimension),
    exact = similR:::exact_match_score(query, dimension)
  )
  expect_true(all(vapply(scores, function(x) all(x >= 0 & x <= 1), logical(1))))
  expect_gt(scores$tfidf[[1L]], scores$tfidf[[2L]])
  expect_gt(scores$bm25[[1L]], scores$bm25[[2L]])
})

test_that("cosine similarity handles regular and zero vectors", {
  expect_equal(similR:::cosine_similarity(c(1, 0), c(1, 0)), 1)
  expect_equal(similR:::cosine_similarity(c(0, 0), c(1, 0)), 0)
})

test_that("exact terms use complete word boundaries", {
  expect_true("sem" %in% similR:::extract_exact_terms("SEM analysis"))
  expect_false("sem" %in% similR:::extract_exact_terms("semester analysis"))
})
