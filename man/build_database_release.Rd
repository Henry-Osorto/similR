\name{build_database_release}
\alias{build_database_release}
\title{Build a versioned DuckDB data release}
\usage{
build_database_release(
  data,
  previous_database = NULL,
  data_version,
  model_name = package_config()$default_model,
  output_dir,
  embeddings = NULL,
  generate_embeddings = FALSE,
  batch_size = 32L,
  overwrite = FALSE
)
}
\arguments{
\item{data}{Processed article data.}
\item{previous_database}{Optional previous DuckDB file.}
\item{data_version}{Version in \code{YYYY.MM} format.}
\item{model_name}{Embedding model identifier recorded in metadata.}
\item{output_dir}{Release output directory.}
\item{embeddings}{Optional data frame containing precomputed embeddings.}
\item{generate_embeddings}{Generate embeddings locally for new or modified
articles when \code{embeddings} is \code{NULL}.}
\item{batch_size}{Positive encoding batch size.}
\item{overwrite}{Whether an existing nonempty directory may be replaced.}
}
\value{An object of class \code{similR_release}.}
\description{
Creates and validates the DuckDB database, manifest, SHA-256 checksums, and
release notes. It can build a lexical-only release or a release with complete
multidimensional semantic embeddings.
}
