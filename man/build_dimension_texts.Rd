\name{build_dimension_texts}
\alias{build_dimension_texts}
\title{Build texts for the similarity dimensions}
\usage{
build_dimension_texts(
  data,
  language = c("auto", "es", "en", "multilingual")
)
}
\arguments{
\item{data}{Processed bibliographic data.}
\item{language}{Language strategy recorded with the generated fields.}
}
\value{A tibble with theme, purpose, method, data, and context texts, sources, and confidence scores.}
\description{Uses explicit fields, bilingual sentence rules, and deterministic fallbacks.}
