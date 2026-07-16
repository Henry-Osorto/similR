\name{process_scopus}
\alias{process_scopus}
\title{Process Scopus or generic bibliographic data}
\usage{
process_scopus(
  data,
  column_map = NULL,
  source = c("auto", "scopus", "generic"),
  remove_duplicates = TRUE
)
}
\arguments{
\item{data}{A data frame containing bibliographic records.}
\item{column_map}{Optional named vector mapping canonical fields to source columns.}
\item{source}{Declared source format.}
\item{remove_duplicates}{Whether exact duplicate groups should be consolidated.}
}
\value{A processed tibble with stable identifiers and diagnostic attributes.}
\description{Normalizes fields, DOI values, authors, keywords, identifiers, content hashes, and exact duplicates.}
