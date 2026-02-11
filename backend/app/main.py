from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager
import os
import logging
from .database import create_tables
from .api import adminEP, clientEP, publicEP, authEP

# Configuración de Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("uvicorn")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Gestión del ciclo de vida de la aplicación.
    - Inicio: Crea carpeta de uploads y verifica tablas DB.
    - Cierre: (Disponible para cleanup si fuera necesario).
    """
    # Crear carpeta de uploads si no existe para evitar errores
    os.makedirs("static/uploads", exist_ok=True)

    logger.info("[STARTUP] Inicializando base de datos...")
    await create_tables()
    logger.info("[STARTUP] Tablas verificadas.")
    yield


app = FastAPI(
    title="Pilates All Canning API",
    description="Backend para la gestión del estudio Pilates All Canning.",
    version="1.0.0",
    lifespan=lifespan,
)

# Configuración de CORS (Seguridad: Restringir en prod con CORS_ORIGINS=https://midominio.com)
cors_origins_str = os.getenv("CORS_ORIGINS", "*")
cors_origins = [o.strip() for o in cors_origins_str.split(",")] if cors_origins_str != "*" else ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=cors_origins_str != "*",  # Solo con orígenes específicos
    allow_methods=["*"],
    allow_headers=["*"],
)

# Servir archivos estáticos (imágenes, certificados)
app.mount("/static", StaticFiles(directory="static"), name="static")

# Conectar Routers
app.include_router(authEP.router)
app.include_router(publicEP.router)
app.include_router(clientEP.router)
app.include_router(adminEP.router)


@app.get("/")
def read_root():
    """Endpoint de salud (Health Check)."""
    return {"status": "ok", "service": "Pilates All Canning Backend", "version": "1.0.0"}
