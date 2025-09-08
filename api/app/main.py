from fastapi import FastAPI          # Framework web moderno y rápido para APIs
from pydantic import BaseModel       # Para validación de datos

app = FastAPI(title="FastAPI on Cloud Run", version="1.0.0")

# Modelo de datos para respuestas estructuradas
class Ping(BaseModel):
    message: str = "pong"

# ✅ Health checks tolerantes:
# - Acepta GET y HEAD (algunos probes usan HEAD)
# - Acepta con y sin slash final (/healthz y /healthz/)
@app.api_route("/healthz", methods=["GET", "HEAD"])
@app.api_route("/healthz/", methods=["GET", "HEAD"])
def healthz():
    # Devolvemos 200 siempre que la app esté viva
    return {"status": "ok"}

# Alias opcional por si alguna herramienta consulta /health
@app.api_route("/health", methods=["GET", "HEAD"])
def health_alias():
    return {"status": "ok"}

# Endpoint simple para testing - responde con "pong" cuando le haces ping
@app.get("/ping", response_model=Ping)
def ping():
    return Ping()

# Endpoint raíz - primera página que ves al visitar la URL
@app.get("/")
def root():
    return {"hello": "cloud run + jenkins"}
