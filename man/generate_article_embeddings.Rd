\name{generate_article_embeddings}
\alias{generate_article_embeddings}
\title{Generate article embeddings for a data release}
\usage{
generate_article_embeddings(
  data,
  previous_database = NULL,
  model_name = package_config()$default_model,
  batch_size = 32L
)
}
\arguments{
\item{data}{Processed article data, preferably after
\code{build_dimension_texts()}.}
\item{previous_database}{Optional previous DuckDB database used to avoid
regenerating unchanged compatible embeddings.}
\item{model_name}{Locally downloaded Sentence Transformer model.}
\item{batch_size}{Positive encoding batch size.}
}
\value{
A tibble with \code{article_id}, \code{dimension}, \code{model_name},
\code{normalized}, and a list-column named \code{embedding}.
}
\description{
Encodes the theme, purpose, method, data, and context texts as passages. When a
compatible previous database is supplied, only new and modified articles are
encoded; unchanged embeddings are reused during release construction.
}
\examples{
\dontrun{
embeddings <- generate_article_embeddings(
  processed_articles,
  model_name = "intfloat/multilingual-e5-base"
)
}
}
