#' Recommend related institutional scientific articles
#'
#' Compares a research description with the locally installed bibliographic
#' database. The lexical engine combines TF-IDF, BM25, and exact-term overlap.
#' The semantic engine compares normalized multilingual sentence embeddings.
#'
#' @param title Research title or thematic description.
#' @param purpose Research purpose or objective.
#' @param method Proposed method or analytical strategy.
#' @param data Data source, sample, or dataset description.
#' @param context Population, sector, country, or geographic context.
#' @param engine Recommendation engine: `"auto"`, `"semantic"`, or `"lexical"`.
#' @param n Number of recommendations to return.
#' @param weights Optional named vector of dimension weights.
#' @param filters Optional list with `year_min`, `year_max`, `years`,
#'   `source_title`, `authors`, `doi`, or `article_id`.
#'
#' @return A tibble ordered from highest to lowest similarity.
#' @export
#' @examples
#' \dontrun{
#' recommend_articles(
#'   title = "Artificial intelligence literacy and entrepreneurial intention",
#'   purpose = "Assess whether AI literacy increases entrepreneurial intention",
#'   method = "Survey and structural equation model",
#'   context = "University students in Honduras",
#'   engine = "auto"
#' )
#' }
recommend_articles <- function(
    title = NULL,
    purpose = NULL,
    method = NULL,
    data = NULL,
    context = NULL,
    engine = c("auto", "semantic", "lexical"),
    n = 20,
    weights = NULL,
    filters = list()) {
  requested_engine <- match.arg(engine)
  database_path <- local_database_path(must_exist = TRUE)
  resolved_engine <- select_engine(
    requested_engine,
    database_path = database_path,
    notify = identical(requested_engine, "auto")
  )
  query <- prepare_user_query(
    title = title,
    purpose = purpose,
    method = method,
    data = data,
    context = context
  )

  if (identical(resolved_engine, "lexical")) {
    index <- load_lexical_index(database_path)
    return(rank_articles_lexical(
      query = query,
      lexical_index = index,
      n = n,
      weights = weights,
      filters = filters
    ))
  }

  rank_articles_semantic(
    query = query,
    database_path = database_path,
    n = n,
    weights = weights,
    filters = filters
  )
}
