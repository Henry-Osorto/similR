
test_that("query module returns validated research fields", {
  module_path <- testthat::test_path(
    "..", "..", "inst", "app", "R", "mod_query_form.R"
  )
  source(module_path, local = TRUE)
  shiny::testServer(mod_query_form_server, {
    session$setInputs(
      title = "AI literacy and entrepreneurship",
      purpose = "Assess entrepreneurial intention",
      method = "Survey",
      data = "Student questionnaire",
      context = "Honduras",
      n_results = 20,
      engine = "lexical",
      weight_theme = 0.20,
      weight_method = 0.22,
      weight_data = 0.10,
      weight_context = 0.23,
      weight_purpose = 0.25,
      year_min = "",
      year_max = "",
      source_title = "",
      search = 1
    )
    result <- query()
    expect_identical(result$title, "AI literacy and entrepreneurship")
    expect_identical(result$engine, "lexical")
    expect_equal(sum(result$weights), 1)
  })
})
