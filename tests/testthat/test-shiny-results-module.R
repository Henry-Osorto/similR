
test_that("results module exposes the selected article", {
  module_path <- testthat::test_path(
    "..", "..", "inst", "app", "R", "mod_results_table.R"
  )
  source(module_path, local = TRUE)
  values <- shiny::reactiveVal(tibble::tibble(
    rank = 1L,
    index = 90,
    similarity_theme = 95,
    similarity_method = 85,
    similarity_data = NA_real_,
    similarity_context = 80,
    similarity_purpose = 90,
    title = "Example article",
    authors = "Author A",
    year = 2026L,
    doi = "10.1000/example",
    keywords = "example",
    source_title = "Journal",
    abstract = "Abstract",
    article_id = "id-1",
    explanation = "Explanation",
    engine = "lexical"
  ))
  shiny::testServer(
    mod_results_table_server,
    args = list(results = values),
    {
      session$setInputs(table_rows_selected = 1L)
      expect_identical(selected()$article_id[[1L]], "id-1")
    }
  )
})
