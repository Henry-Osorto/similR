\name{run_app}
\alias{run_app}
\title{Run the local similR Shiny application}
\usage{
run_app(
  engine = c("auto", "semantic", "lexical"),
  check_updates = TRUE,
  launch.browser = TRUE,
  host = "127.0.0.1",
  port = NULL
)
}
\arguments{
\item{engine}{Recommendation engine. In Phase 2, \code{"auto"} resolves to \code{"lexical"}.}
\item{check_updates}{Check GitHub Releases before opening the app.}
\item{launch.browser}{Value passed to \code{shiny::runApp()}.}
\item{host}{Local host passed to \code{shiny::runApp()}.}
\item{port}{Optional local port.}
}
\description{Ensures a verified local database is present and opens the packaged Shiny application.}
\examples{
\dontrun{run_app(engine = "lexical")}
}
