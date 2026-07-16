\name{recommend_articles}
\alias{recommend_articles}
\title{Recommend related institutional scientific articles}
\usage{
recommend_articles(
  title = NULL,
  purpose = NULL,
  method = NULL,
  data = NULL,
  context = NULL,
  engine = c("auto", "semantic", "lexical"),
  n = 20,
  weights = NULL,
  filters = list()
)
}
\arguments{
\item{title}{Research title or thematic description.}
\item{purpose}{Research purpose or objective.}
\item{method}{Proposed method or analytical strategy.}
\item{data}{Data source, sample, or dataset description.}
\item{context}{Population, sector, country, or geographic context.}
\item{engine}{Recommendation engine. Automatic mode uses semantic retrieval
only when Python, the local model, and compatible database embeddings are all
available; otherwise it uses the lexical engine.}
\item{n}{Number of recommendations to return.}
\item{weights}{Optional named vector of dimension weights.}
\item{filters}{Optional list of bibliographic filters.}
}
\value{
A tibble ordered from highest to lowest similarity.
}
\description{
Compares a research description with the locally installed bibliographic
database. The lexical engine combines TF-IDF, BM25, and exact-term overlap. The
semantic engine compares normalized multilingual embeddings for five separate
dimensions.
}
\examples{
\dontrun{
recommend_articles(
  title = "Artificial intelligence literacy and entrepreneurial intention",
  purpose = "Assess whether AI literacy increases entrepreneurial intention",
  method = "Survey and structural equation model",
  context = "University students in Honduras",
  engine = "auto"
)
}
}
