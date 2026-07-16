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
  overwrite = FALSE
)
}
\arguments{
\item{data}{Processed article data.}
\item{previous_database}{Optional previous DuckDB file.}
\item{data_version}{Version in YYYY.MM format.}
\item{model_name}{Embedding model identifier recorded in metadata.}
\item{output_dir}{Release output directory.}
\item{embeddings}{Optional data frame containing precomputed embeddings.}
\item{overwrite}{Whether an existing nonempty directory may be replaced.}
}
\value{An object of class \code{similR_release}.}
\description{Creates the DuckDB database, manifest, checksums, release notes, and validates the complete release.}
