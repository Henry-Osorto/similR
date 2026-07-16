\name{download_embedding_model}
\alias{download_embedding_model}
\title{Download a local embedding model}
\usage{
download_embedding_model(
  model_name = package_config()$default_model,
  force = FALSE
)
}
\arguments{
\item{model_name}{Sentence Transformer model identifier.}
\item{force}{Replace an existing local copy and skip interactive confirmation.}
}
\value{
Invisibly, an object of class \code{similR_semantic_status}.
}
\description{
Downloads a Sentence Transformer model only after explicit invocation and
stores a self-contained copy under the similR user cache. The download is
staged and activated only after the local model files have been saved.
}
\examples{
\dontrun{
install_semantic_engine()
download_embedding_model()
}
}
