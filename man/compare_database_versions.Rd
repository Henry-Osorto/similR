\name{compare_database_versions}
\alias{compare_database_versions}
\title{Compare article data with a previous database}
\usage{
compare_database_versions(new_data, previous_database)
}
\arguments{
\item{new_data}{Newly processed article data.}
\item{previous_database}{Previous DuckDB path or compatible data frame.}
}
\value{An object of class \code{similR_database_comparison}.}
\description{Classifies article identifiers as new, modified, unchanged, or removed using content hashes.}
