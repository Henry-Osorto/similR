\name{database_info}
\alias{database_info}
\alias{print.similR_database_info}
\title{Information about the locally installed bibliographic database}
\usage{
database_info()
\method{print}{similR_database_info}(x, ...)
}
\arguments{
\item{x}{A database information object.}
\item{...}{Unused.}
}
\value{An object of class \code{similR_database_info}.}
\description{Reports database path, version, size, article count, checksum, embedding metadata, schema, and compatibility.}
\examples{\dontrun{database_info()}}
