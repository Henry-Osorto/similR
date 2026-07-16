\name{check_semantic_engine}
\alias{check_semantic_engine}
\title{Check the local semantic engine}
\usage{
check_semantic_engine(
  model_name = package_config()$default_model
)
}
\arguments{
\item{model_name}{Sentence Transformer model identifier.}
}
\value{
An object of class \code{similR_semantic_status} with Python, module, model,
and readiness information.
}
\description{
Inspects Python, the required Python modules, and the locally downloaded
embedding model without downloading files or creating a new model copy.
}
