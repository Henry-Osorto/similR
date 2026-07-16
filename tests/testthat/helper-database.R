create_test_articles <- function() {
  raw <- tibble::tibble(
    Title = c(
      "Artificial intelligence literacy and entrepreneurial intention",
      "Digital taxation and firm innovation"
    ),
    Authors = c("Ana Pérez; Juan López", "María Díaz"),
    Abstract = c(
      "This study aims to assess entrepreneurial intention among university students. A survey and structural equation model are used in Honduras.",
      "We examine digital tax filing and product innovation using enterprise survey data from emerging markets."
    ),
    Keywords = c("artificial intelligence; entrepreneurship", "taxation; innovation"),
    DOI = c("https://doi.org/10.1000/ABC.1", "10.1000/abc.2"),
    Year = c(2026L, 2025L),
    Source = c("Journal A", "Journal B")
  )
  process_scopus(
    raw,
    column_map = c(
      title = "Title", authors = "Authors", abstract = "Abstract",
      author_keywords = "Keywords", doi = "DOI", year = "Year",
      source_title = "Source"
    ),
    source = "generic"
  ) |>
    build_dimension_texts()
}

create_test_manifest <- function(database_file, sha256, n = 1, embedding_status = "absent") {
  list(
    data_version = "2026.07",
    published_at = "2026-07-15",
    database_file = database_file,
    database_schema_version = "1.0",
    number_of_articles = n,
    embedding_model = "intfloat/multilingual-e5-base",
    embedding_status = embedding_status,
    embedding_dimensions = if (embedding_status == "absent") 0L else 768L,
    embedding_normalized = embedding_status != "absent",
    query_prefix = "query: ",
    passage_prefix = "passage: ",
    minimum_package_version = "0.4.0",
    semantic_index_version = "1.0",
    sha256 = sha256
  )
}

create_test_database <- function(path, n = 2L) {
  articles <- create_test_articles()
  if (n < nrow(articles)) articles <- articles[seq_len(n), , drop = FALSE]
  if (n == 0L) articles <- articles[0, , drop = FALSE]
  directory <- tempfile("release-")
  dir.create(directory)
  release <- build_database_release(
    data = articles,
    data_version = "2026.07",
    output_dir = directory,
    overwrite = TRUE
  )
  file.copy(release$database_path, path, overwrite = TRUE)
  invisible(path)
}

install_test_release <- function(release, data_dir) {
  dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)
  file.copy(
    release$database_path,
    file.path(data_dir, basename(release$database_path)),
    overwrite = TRUE
  )
  manifest <- release$manifest
  manifest$installed_at <- "2026-07-15T12:00:00Z"
  jsonlite::write_json(
    manifest,
    file.path(data_dir, "manifest.json"),
    auto_unbox = TRUE,
    pretty = TRUE
  )
  invisible(data_dir)
}


create_test_embeddings <- function(articles = create_test_articles(), dimensions = 4L) {
  dimensions <- as.integer(dimensions)
  stopifnot(dimensions >= 2L)
  vectors <- lapply(seq_len(nrow(articles)), function(i) {
    vector <- rep(0, dimensions)
    vector[[((i - 1L) %% dimensions) + 1L]] <- 1
    vector
  })
  tidyr::crossing(
    article_id = articles$article_id,
    dimension = similR:::package_config()$dimensions
  ) |>
    dplyr::mutate(
      model_name = "intfloat/multilingual-e5-base",
      normalized = TRUE,
      embedding = lapply(.data$article_id, function(id) {
        vectors[[match(id, articles$article_id)]]
      })
    )
}

create_test_semantic_release <- function(
    output_dir = tempfile("semantic-release-"),
    articles = create_test_articles()) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  build_database_release(
    data = articles,
    data_version = "2026.07",
    output_dir = output_dir,
    embeddings = create_test_embeddings(articles),
    overwrite = TRUE
  )
}

mock_semantic_status <- function(ready = TRUE) {
  structure(
    list(
      python_available = ready,
      python_version = if (ready) "3.12.0" else NA_character_,
      python_path = if (ready) "/tmp/python" else NA_character_,
      python_version_supported = ready,
      sentence_transformers_available = ready,
      sentence_transformers_version = if (ready) "5.0.0" else NA_character_,
      numpy_available = ready,
      numpy_version = if (ready) "2.0.0" else NA_character_,
      model_downloaded = ready,
      model_name = "intfloat/multilingual-e5-base",
      model_path = "/tmp/model",
      model_dimensions = if (ready) 4L else NA_integer_,
      model_size_bytes = 0,
      model_size = "0.00 B",
      ready = ready
    ),
    class = "similR_semantic_status"
  )
}
