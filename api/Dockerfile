# Imagen base: Python 3.12 en versión "slim" (más pequeña y segura)
FROM python:3.12-slim

# (Comentario en línea separada) No crear .pyc y sacar logs sin buffer (útil en contenedores)
# OJO: no pongas comentarios en las mismas líneas que terminan con "\".
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Instalar herramientas del sistema necesarias
# --no-install-recommends: solo instala lo esencial (imagen más pequeña)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# SEGURIDAD: Crear usuario sin privilegios de administrador
RUN useradd -m appuser

# Directorio donde vivirá nuestra aplicación
WORKDIR /app

# Instalar dependencias Python ANTES de copiar el código (mejor cache de capas)
# Asegúrate de que "requirements.txt" está en la misma carpeta que este Dockerfile (api/requirements.txt).
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código de la app (asumiendo estructura api/app/*)
COPY app ./app

# Puerto por defecto (Cloud Run puede sobreescribir PORT)
ENV PORT=8000

# (Opcional) Asegurar ownership de /app si tu app escribe algo
# RUN chown -R appuser:appuser /app

# Ejecutar como usuario sin privilegios
USER appuser

# Comando de arranque: ajusta "app.main:app" si tu módulo es distinto
CMD exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT}
