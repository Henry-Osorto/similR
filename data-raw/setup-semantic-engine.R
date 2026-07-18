# Forzar el entorno administrado antes de inicializar Python.
Sys.setenv(RETICULATE_PYTHON = "managed",
           RETICULATE_USE_MANAGED_VENV = "yes")

# Cargar el paquete en desarrollo.
devtools::load_all()

# Declarar y preparar las dependencias Python.
install_semantic_engine(model_name = "intfloat/multilingual-e5-base")
