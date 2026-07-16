# Administrative script: build a data Release for GitHub.
# Run from the package project after replacing the input path and version.

library(similR)

raw_data <- import_article_data(
  path = "data-raw/input/institutional_articles.csv"
)

processed <- process_scopus(
  raw_data,
  column_map = c(
    title = "Title",
    authors = "Authors",
    abstract = "Abstract",
    author_keywords = "Keywords",
    doi = "DOI",
    year = "Year",
    source_title = "Source"
  ),
  source = "generic"
)

processed <- build_dimension_texts(processed)

release <- build_database_release(
  data = processed,
  previous_database = NULL,
  data_version = "2026.07",
  model_name = "intfloat/multilingual-e5-base",
  output_dir = "release/2026.07",
  overwrite = TRUE
)

print(release)
