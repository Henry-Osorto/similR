
# similR

`similR` es un paquete de R y una aplicación Shiny local para descubrir artículos científicos institucionales relacionados con una nueva investigación.

## Estado de desarrollo

La Fase 3 incorpora:

- ciclo local de datos y actualización mediante GitHub Releases;
- importación y procesamiento de bases bibliográficas institucionales;
- limpieza, deduplicación e identificadores estables;
- construcción de textos para tema, propósito, método, datos y contexto;
- base DuckDB y preparación incremental de Releases;
- índice lexical local mediante matrices dispersas;
- similitud coseno TF-IDF;
- ranking BM25;
- coincidencias exactas de métodos, países, poblaciones, bases de datos y DOI;
- ponderación multidimensional con renormalización de campos vacíos;
- función programática `recommend_articles()`;
- aplicación Shiny modular con tabla, filtros, descarga y detalles.

El motor semántico con embeddings y Python se incorporará en la Fase 4. Mientras tanto, `engine = "auto"` selecciona el motor lexical.

## Instalación durante el desarrollo

```r
install.packages("pak")

pak::pkg_install(
  "REPLACE_GITHUB_OWNER/REPLACE_GITHUB_REPOSITORY"
)

library(similR)
```

## Configurar el repositorio de datos

```r
options(
  similR.github_owner = "YOUR_GITHUB_USER_OR_ORGANIZATION",
  similR.github_repo = "YOUR_DATA_REPOSITORY"
)
```

Antes de publicar el paquete, estos valores deben definirse en `R/config.R`.

## Abrir la aplicación

```r
run_app()
```

También puede solicitar explícitamente el motor lexical:

```r
run_app(engine = "lexical")
```

## Recomendación programática

```r
results <- recommend_articles(
  title = "Artificial intelligence literacy and entrepreneurial intention",
  purpose = "Assess whether AI literacy increases entrepreneurial intention",
  method = "Survey and structural equation model",
  data = "Questionnaire applied to university students",
  context = "University students in Honduras",
  engine = "lexical",
  n = 20
)

results
```

El resultado contiene el índice general, las cinco puntuaciones dimensionales y una explicación determinística.

## Fórmula lexical

Para cada dimensión se calcula:

```text
Lexical = 0.45 × TF-IDF + 0.35 × BM25 + 0.20 × ExactMatch
```

Después, las dimensiones se combinan con los pesos predeterminados:

```r
c(
  theme = 0.20,
  method = 0.22,
  data = 0.10,
  context = 0.23,
  purpose = 0.25
)
```

Los pesos se renormalizan automáticamente cuando el usuario deja campos vacíos.

## Filtros

```r
recommend_articles(
  title = "Digital taxation and innovation",
  filters = list(
    year_min = 2020,
    year_max = 2026,
    source_title = "Economics"
  )
)
```

## Construir una Release de datos

```r
raw <- import_article_data(
  "data-raw/input/institutional_articles.csv"
)

processed <- process_scopus(
  raw,
  column_map = c(
    title = "Title",
    authors = "Authors",
    abstract = "Abstract",
    author_keywords = "Keywords",
    doi = "DOI",
    year = "Year",
    source_title = "Source"
  ),
  source = "generic"
)

processed <- build_dimension_texts(processed)

release <- build_database_release(
  data = processed,
  data_version = "2026.07",
  output_dir = "release/2026.07"
)

validate_release(release)
```

La carpeta generada contiene:

```text
university_articles_2026-07.duckdb
manifest.json
checksums.txt
release_notes.md
```

Los primeros tres archivos se publican como assets de la misma GitHub Release.

## Actualizar la base local

```r
check_database_update()
update_database()
database_info()
```

## Privacidad

El motor lexical funciona completamente en local. La aplicación no implementa telemetría y no envía las descripciones de investigación a servicios externos.

## Uso responsable

Las recomendaciones indican proximidad documental; no sustituyen la revisión académica. Cada artículo debe citarse únicamente cuando contribuya de manera sustantiva a la investigación.
