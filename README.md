# similR

`similR` es un paquete de R y una aplicación Shiny local para descubrir artículos científicos institucionales relacionados con una nueva investigación.

## Capacidades actuales

- descarga y actualización de bases DuckDB publicadas mediante GitHub Releases;
- importación, limpieza, deduplicación y versionado de registros bibliográficos;
- construcción de textos para tema, propósito, método, datos y contexto;
- motor lexical local basado en TF-IDF, BM25 y coincidencias exactas;
- motor semántico opcional basado en embeddings multilingües;
- integración R–Python mediante `reticulate`;
- selección automática del motor disponible;
- aplicación Shiny modular y ejecución programática.

## Instalación desde GitHub

```r
install.packages("pak")
pak::pkg_install("Henry-Osorto/similR")
library(similR)
```

Configure el repositorio que contiene las Releases de datos:

```r
options(
  similR.github_owner = "Henry-Osorto",
  similR.github_repo = "similR"
)
```

## Inicio rápido

```r
run_app(engine = "auto")
```

En modo automático:

1. se usa el motor semántico cuando Python, el modelo local y los embeddings de la base son compatibles;
2. en caso contrario, se usa el motor lexical sin interrumpir la aplicación.

## Motor lexical

```r
run_app(engine = "lexical")
```

Para cada dimensión se calcula:

```text
Lexical = 0.45 × TF-IDF + 0.35 × BM25 + 0.20 × ExactMatch
```

## Motor semántico

El motor semántico es opcional. El paquete puede instalarse, cargarse y ejecutar el motor lexical sin Python.

### 1. Preparar Python

```r
install_semantic_engine()
```

La función declara un entorno compatible con Python 3.10 o superior y las dependencias `sentence-transformers` y `numpy`. No descarga el modelo.

### 2. Descargar el modelo

```r
download_embedding_model()
```

En una sesión no interactiva:

```r
download_embedding_model(force = TRUE)
```

El modelo predeterminado es:

```text
intfloat/multilingual-e5-base
```

La copia local se guarda en el directorio de caché obtenido mediante `tools::R_user_dir("similR", "cache")`.

### 3. Comprobar el estado

```r
check_semantic_engine()
```

### 4. Ejecutar

```r
run_app(engine = "semantic")
```

Los textos no se envían a una API externa. Tanto el modelo como la base y el ranking se ejecutan localmente.

## Recomendación programática

```r
results <- recommend_articles(
  title = "Artificial intelligence literacy and entrepreneurial intention",
  purpose = "Assess whether AI literacy increases entrepreneurial intention",
  method = "Survey and structural equation model",
  data = "Questionnaire applied to university students",
  context = "University students in Honduras",
  engine = "auto",
  n = 20
)

results
```

## Construir una Release lexical

```r
raw <- import_article_data("data-raw/input/institutional_articles.csv")

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
```

## Construir una Release semántica

Primero instale el motor y descargue el mismo modelo que utilizarán los usuarios:

```r
install_semantic_engine()
download_embedding_model()
```

Después genere los embeddings dentro del flujo de construcción:

```r
release <- build_database_release(
  data = processed,
  previous_database = NULL,
  data_version = "2026.07",
  model_name = "intfloat/multilingual-e5-base",
  output_dir = "release/2026.07",
  generate_embeddings = TRUE,
  batch_size = 32,
  overwrite = TRUE
)

validate_release(release)
```

En actualizaciones posteriores, `generate_article_embeddings()` codifica únicamente artículos nuevos o modificados cuando la base anterior es compatible. `build_database_release()` reutiliza los embeddings de los artículos sin cambios.

## Archivos de la Release

```text
university_articles_2026-07.duckdb
manifest.json
checksums.txt
release_notes.md
```

Los primeros tres archivos deben cargarse como assets de una misma GitHub Release.

## Actualización local

```r
check_database_update()
update_database()
database_info()
```

## Privacidad y uso responsable

Los motores disponibles funcionan localmente y no implementan telemetría. Las recomendaciones indican proximidad documental; cada artículo debe revisarse y citarse únicamente cuando contribuya sustantivamente a la investigación.
