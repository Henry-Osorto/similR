\name{remove_local_database}
\alias{remove_local_database}
\title{Remove locally managed bibliographic database files}
\usage{remove_local_database(force = FALSE)}
\arguments{\item{force}{Skip the interactive confirmation.}}
\value{Invisibly, the paths that existed before removal.}
\description{Removes only the local database, manifest, and staging directories. It does not remove semantic models or other cache content.}
\examples{\dontrun{remove_local_database()}}
