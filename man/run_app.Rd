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
\item{engine}{Recommendation engine. Automatic mode selects semantic retrieval
only when all local semantic components are ready; otherwise it uses lexical
retrieval.}
\item{check_updates}{Check GitHub Releases before opening the app.}
\item{launch.browser}{Value passed to \code{shiny::runApp()}.}
\item{host}{Local host passed to \code{shiny::runApp()}.}
\item{port}{Optional local port.}
}
\value{The value returned by \code{shiny::runApp()}, invisibly.}
\description{
Ensures a verified local database is present, resolves the requested engine,
and opens the modular Shiny recommendation application.
}
\examples{
\dontrun{
run_app(engine = "auto")
}
}
