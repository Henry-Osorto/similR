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
\item{engine}{Recommendation engine. In Phase 3, \code{"auto"} resolves to the local lexical engine; the semantic engine is reserved for Phase 4.}
\item{check_updates}{Check GitHub Releases before opening the app.}
\item{launch.browser}{Value passed to \code{shiny::runApp()}.}
\item{host}{Local host passed to \code{shiny::runApp()}.}
\item{port}{Optional local port.}
}
\description{Ensures a verified local database is present and opens the modular Shiny recommendation application.}
\examples{
\dontrun{run_app(engine = "lexical")}
}
