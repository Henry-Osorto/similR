\name{validate_release}
\alias{validate_release}
\title{Validate a complete data release}
\usage{
validate_release(release)
}
\arguments{
\item{release}{A \code{similR_release} object or release directory.}
}
\value{A structured validation result.}
\description{Checks required files, SHA-256 consistency, DuckDB schema, metadata, and article counts.}
