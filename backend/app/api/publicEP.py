from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from sqlmodel import select
from typing import Dict
from app.database import get_session
from app.models import Setting

router = APIRouter()

# ----------- HEALTH CHECK -----------


@router.get("/health", response_model=Dict[str, str])
async def health_check(session: AsyncSession = Depends(get_session)):
    """
    Verifica la disponibilidad del servicio y la conexión a la base de datos.
    """
    try:
        # Consulta de bajo coste para validar conectividad
        await session.execute(text("SELECT 1"))
        return {"status": "ok", "db": "connected"}
    except Exception as e:
        return {"status": "error", "db": str(e)}


# ----------- SETTINGS -----------


@router.get("/settings", response_model=Dict[str, str])
async def get_settings(session: AsyncSession = Depends(get_session)):
    """
    Recupera configuraciones globales accesibles sin autenticación.
    Disponible para datos esenciales para la inicialización del cliente
    """
    result = await session.execute(select(Setting))
    settings = result.scalars().all()

    # Mapeo de entidades a diccionario simple
    return {item.key: item.value for item in settings}
