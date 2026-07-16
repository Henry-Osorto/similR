test_that("embedding serialization is reversible", {
  x <- c(0.1, -0.2, 0.3)
  stored <- similR:::serialize_embedding_vector(x)
  restored <- similR:::deserialize_embedding_vector(stored)
  expect_equal(restored, x)
})
