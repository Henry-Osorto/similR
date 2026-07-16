\name{update_database}
\alias{update_database}
\title{Download and install the latest bibliographic database}
\usage{update_database(force = FALSE, quiet = FALSE)}
\arguments{
\item{force}{Reinstall even when the installed data version is current.}
\item{quiet}{Suppress informational messages and progress.}
}
\value{Invisibly, a list describing the update.}
\description{Downloads a staged GitHub Release bundle, verifies its checksum and DuckDB schema, and installs it with rollback protection.}
\examples{\dontrun{update_database()}}
