
test_that("user query preserves the five dimensions", {
  query <- similR:::prepare_user_query(
    title = "  Artificial intelligence and entrepreneurship  ",
    purpose = "Assess entrepreneurial intention",
    method = "Survey",
    data = "Student questionnaire",
    context = "Honduras"
  )
  expect_identical(names(query), c("theme", "purpose", "method", "data", "context"))
  expect_identical(unname(query[["theme"]]), "Artificial intelligence and entrepreneurship")
  expect_identical(attr(query, "available_dimensions"), names(query))
})

test_that("empty queries are rejected", {
  expect_error(
    similR:::prepare_user_query(),
    class = "similR_empty_query"
  )
})

test_that("query fields have a length limit", {
  expect_error(
    similR:::prepare_user_query(title = paste(rep("x", 20001), collapse = "")),
    class = "similR_query_too_long"
  )
})
