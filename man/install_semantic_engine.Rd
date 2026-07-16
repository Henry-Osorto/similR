\name{install_semantic_engine}
\alias{install_semantic_engine}
\title{Install or prepare the local semantic engine}
\usage{
install_semantic_engine(
  model_name = package_config()$default_model
)
}
\arguments{
\item{model_name}{Model identifier recorded for status reporting. The model is
not downloaded by this function.}
}
\value{
Invisibly, an object of class \code{similR_semantic_status}.
}
\description{
Declares the Python requirements through \code{reticulate::py_require()} and
initializes the local Python runtime with sentence-transformers and NumPy. The
embedding model must be downloaded separately with
\code{download_embedding_model()}.
}
