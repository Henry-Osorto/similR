
#' Recommend related institutional scientific articles
#'
#' Compares a research description with the locally installed bibliographic
#' database. In Phase 3 the lexical engine combines TF-IDF cosine similarity,
#' BM25, and exact-term overlap independently for five dimensions.
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
#'   engine = "lexical"
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
  engine <- select_engine(engine)
  query <- prepare_user_query(
    title = title,
    purpose = purpose,
    method = method,
    data = data,
    context = context
  )

  if (identical(engine, "lexical")) {
    index <- load_lexical_index(local_database_path(must_exist = TRUE))
    return(rank_articles_lexical(
      query = query,
      lexical_index = index,
      n = n,
      weights = weights,
      filters = filters
    ))
  }

  rlang::abort("El motor solicitado todavía no está disponible.")
}
