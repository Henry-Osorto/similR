# similR — Arquitectura de la Fase 4

## Objetivo

La Fase 4 incorpora un motor semántico local y opcional sin eliminar ni debilitar el motor lexical desarrollado en la Fase 3.

## Flujo del usuario

```text
run_app(engine = "auto")
        │
        ├── Python + módulos + modelo + embeddings compatibles
        │        └── motor semántico
        │
        └── cualquier componente ausente
                 └── motor lexical
```

## Gestión de Python

- `.onLoad()` declara `sentence-transformers` y `numpy` mediante `reticulate::py_require()`.
- `reticulate::import(..., delay_load = TRUE)` evita inicializar Python al cargar el paquete.
- `install_semantic_engine()` inicializa o prepara el entorno únicamente por solicitud explícita.
- `check_semantic_engine()` inspecciona el estado sin descargar el modelo.

## Gestión del modelo

```text
user cache/similR/semantic/
├── engine.json
├── downloads/
└── models/
    └── intfloat--multilingual-e5-base/
        ├── modules.json
        ├── similR-model.json
        └── archivos del modelo
```

La descarga se realiza en staging y la copia anterior solo se reemplaza después de guardar correctamente el nuevo modelo.

## Embeddings

Para cada artículo se generan cinco vectores normalizados:

```text
theme
purpose
method
data
context
```

Los documentos utilizan el prefijo `passage: ` y las consultas utilizan `query: `.

## Actualización incremental

```text
Nueva base procesada
       │
       ├── new / modified ──> generar embeddings
       ├── unchanged ───────> reutilizar embeddings compatibles
       └── removed ─────────> excluir de la nueva Release
```

La reutilización exige el mismo modelo, dimensión, normalización, prefijos y versión del índice semántico.

## Almacenamiento DuckDB

La tabla `embeddings` contiene:

```text
article_id
dimension
model_name
embedding_dimensions
normalized
embedding_blob
content_hash
```

Los vectores se serializan, codifican en base64 y se validan contra los hashes de contenido de la tabla `articles`.

## Ranking

1. Se genera un embedding de consulta por dimensión disponible.
2. Se recupera la matriz de documentos correspondiente.
3. El producto de vectores normalizados produce la similitud coseno.
4. La similitud se transforma al intervalo de 0 a 1.
5. Las dimensiones se combinan con pesos renormalizados.
6. Se devuelven los artículos ordenados en una escala de 0 a 100.

## Rendimiento

Las matrices semánticas se deserializan una vez por base y sesión. Un caché en memoria se invalida automáticamente cuando cambia la ruta, el tamaño, la fecha de modificación o la versión del índice.

## Validación

Una Release solo se considera semánticamente completa cuando:

- contiene cinco embeddings por artículo;
- no tiene pares artículo-dimensión duplicados;
- usa un único modelo y una única dimensión vectorial;
- todos los vectores están normalizados;
- los hashes coinciden con el contenido actual;
- la metadata interna coincide con `manifest.json`;
- los prefijos y la versión del índice son compatibles.
