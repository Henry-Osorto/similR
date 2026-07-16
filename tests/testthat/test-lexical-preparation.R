test_that("lexical preparation creates one row per article and dimension", {
  articles <- create_test_articles()
  lexical <- similR:::build_lexical_documents(articles)
  expect_equal(nrow(lexical), nrow(articles) * 5L)
  expect_true(all(lexical$dimension %in% c("theme", "purpose", "method", "data", "context")))
  expect_true(all(lexical$document_length >= 0L))
})

test_that("technical short terms are retained", {
  tokens <- similR:::tokenize_lexical_text("SEM, R and AI methods")
  expect_true(all(c("sem", "r", "ai") %in% tokens))
})


test_that("lexical documents store normalized text and exact terms", {
  articles <- create_test_articles()
  lexical <- similR:::build_lexical_documents(articles)
  expect_true(all(c("normalized_text", "tokens_json", "exact_terms") %in% names(lexical)))
  expect_true(any(grepl("honduras", lexical$exact_terms, fixed = TRUE)))
})

