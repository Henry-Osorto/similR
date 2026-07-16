\name{import_article_data}
\alias{import_article_data}
\title{Import institutional article data}
\usage{
import_article_data(path, sheet = 1, ...)
}
\arguments{
\item{path}{Path to a CSV, TSV, TXT, RDS, JSON, XLS, or XLSX file.}
\item{sheet}{Excel sheet name or number.}
\item{...}{Additional arguments passed to the selected reader.}
}
\value{A tibble containing the imported records.}
\description{Reads a bibliographic source file without imposing a Scopus-only format.}
