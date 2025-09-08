# Ya tienes este archivo, aquí explico qué hace cada parte:

from fastapi import FastAPI          # Framework web moderno y rápido para APIs
from pydantic import BaseModel       # Para validación de datos
app = FastAPI(title="FastAPI on Cloud Run", version="1.0.0")

# Modelo de datos para respuestas estructuradas
class Ping(BaseModel):
    message: str = "pong"

# Endpoint para health checks - Cloud Run lo usa para verificar que la app está funcionando
@app.get("/healthz")
def healthz():
    return {"status": "ok"}

# Endpoint simple para testing - responde con "pong" cuando le haces ping
@app.get("/ping", response_model=Ping)
def ping():
    return Ping()

# Endpoint raíz - primera página que ves al visitar la URL
@app.get("/")
def root():
    return {"hello": "cloud run + jenkins"}
