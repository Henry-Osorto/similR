# Fase 1 — decisiones arquitectónicas

## Alcance

Esta fase implementa el ciclo de vida seguro de una base bibliográfica DuckDB
separada del paquete. El ranking lexical, embeddings y aplicación completa se
incorporan en fases posteriores sin cambiar los contratos de rutas, manifest o
GitHub Releases.

## Decisiones

1. **Datos separados del paquete.** GitHub Releases contiene la base, manifest y
   checksum; el repositorio principal contiene código.
2. **Release de datos detectable.** Se examinan releases recientes y se toma la
   primera release publicada, no preliminar y no borrador que contenga los tres
   recursos obligatorios.
3. **Descarga atómica.** La base se descarga a una carpeta de staging ubicada en
   el mismo volumen que el directorio final.
4. **Verificación doble.** El hash del manifest debe coincidir con
   `checksums.txt`, y ambos deben coincidir con el archivo descargado.
5. **Validación estructural.** DuckDB debe abrir en modo de solo lectura y
   contener las tablas y columnas contractuales.
6. **Activación por manifest.** La base nueva solo se vuelve activa después de
   escribir correctamente el manifest local.
7. **Rollback.** Si falla la activación, se restaura una base anterior con el
   mismo nombre y el manifest anterior permanece vigente.
8. **Sin efectos en `.onLoad()`.** Cargar el paquete no accede a internet, no
   inicializa Python y no escribe archivos.
9. **Rutas configurables.** En producción se usa `tools::R_user_dir()`; en tests
   se pueden aislar rutas mediante opciones.
10. **Pruebas sin internet.** Las respuestas externas se simulan mediante
    bindings locales.

## Dependencias de Fase 1

- `httr2`: API y descargas HTTP.
- `digest`: SHA-256.
- `DBI` y `duckdb`: apertura y validación de la base.
- `fs`: rutas y sistema de archivos.
- `jsonlite`: manifests.
- `rlang` y `cli`: errores y mensajes estructurados.
- `shiny` y `bslib`: interfaz local mínima de estado.
- `tibble`: representación estable de assets.

Las dependencias de NLP se añadirán únicamente cuando sean utilizadas.

## Árbol definitivo

```text
.Rbuildignore
.gitignore
DESCRIPTION
LICENSE
LICENSE.md
NAMESPACE
NEWS.md
PHASE1_ARCHITECTURE.md
R/checksums.R
R/config.R
R/database-download.R
R/database-info.R
R/database-update.R
R/database-validation.R
R/github-release.R
R/package.R
R/paths.R
R/run-app.R
R/utils.R
R/zzz.R
README.md
UniLitR.Rproj
data-raw/input/.gitkeep
inst/app/app.R
inst/extdata/default-config.json
man/UniLitR-package.Rd
man/check_database_update.Rd
man/database_info.Rd
man/remove_local_database.Rd
man/run_app.Rd
man/update_database.Rd
tests/testthat.R
tests/testthat/helper-database.R
tests/testthat/test-checksums.R
tests/testthat/test-config-paths.R
tests/testthat/test-database-validation.R
tests/testthat/test-install-rollback.R
tests/testthat/test-manifest.R
tests/testthat/test-release-parsing.R
tests/testthat/test-version-update.R
```
