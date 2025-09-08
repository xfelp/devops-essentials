# Tu Dockerfile está muy bien optimizado, aquí explico cada parte:

# Imagen base: Python 3.12 en versión "slim" (más pequeña y segura)
FROM python:3.12-slim

# Variables de entorno para mejorar el comportamiento de Python en contenedores
ENV PYTHONDONTWRITEBYTECODE=1 \    # No crear archivos .pyc (optimización)
    PYTHONUNBUFFERED=1             # Mostrar logs en tiempo real

# Instalar herramientas del sistema que necesitamos
# --no-install-recommends: solo instala lo esencial (imagen más pequeña)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*    # Limpiar caché para reducir tamaño

# SEGURIDAD: Crear usuario sin privilegios de administrador
RUN useradd -m appuser

# Directorio donde vivirá nuestra aplicación
WORKDIR /app

# Instalar dependencias Python ANTES de copiar el código
# Esto aprovecha la caché de Docker: si requirements.txt no cambia, no reinstala
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar nuestro código al contenedor
COPY app ./app

# Puerto que usará la aplicación (Cloud Run detecta automáticamente PORT)
ENV PORT=8000

# SEGURIDAD: Cambiar al usuario sin privilegios
USER appuser

# Comando que ejecuta la aplicación
# uvicorn es el servidor ASGI para FastAPI
CMD exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT}
