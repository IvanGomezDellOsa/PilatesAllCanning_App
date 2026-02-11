import os
from typing import AsyncGenerator
from sqlmodel import SQLModel
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from dotenv import load_dotenv

"""
DATABASE.PY
-----------
Configuración de la conexión asíncrona a PostgreSQL usando SQLAlchemy + SQLModel.
"""

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise ValueError("DATABASE_URL no está definido en .env")

# Motor Asíncrono
# echo=True imprime las queries SQL en consola (útil para debug, deshabilitar en prod)
engine = create_async_engine(
    DATABASE_URL,
    echo=os.getenv("DB_ECHO", "false").lower() == "true",
    future=True,
    pool_pre_ping=True,
)

# Fábrica de Sesiones
async_session_factory = async_sessionmaker(
    engine, class_=AsyncSession, expire_on_commit=False
)


async def get_session() -> AsyncGenerator[AsyncSession, None]:
    """Dependency para inyectar la sesión de DB en los endpoints."""
    async with async_session_factory() as session:
        yield session


# --- Funciones de Utilidad ---
async def create_tables():
    """Crea las tablas al iniciar la app (Idempotente: solo si no existen)."""
    async with engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)


async def dispose_engine():
    """Cierra el pool de conexiones."""
    await engine.dispose()
