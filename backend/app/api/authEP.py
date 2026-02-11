from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select
from app.database import get_session
from app.auth.dependencies import get_current_user
from app.models import User, ProviderType
from app.models import Credit
from app.api.schemas import LoginRequest, UserProfileReadV2
import firebase_admin
from firebase_admin import auth, credentials
import os
import logging
import asyncio
from datetime import datetime

router = APIRouter(prefix="/auth", tags=["auth"])
logger = logging.getLogger("uvicorn")

# Inicialización de Firebase Admin
# Intentamos usar credenciales por defecto (Google Cloud) o explícitas si existen.
try:
    if not firebase_admin._apps:
        cred = credentials.ApplicationDefault()
        firebase_admin.initialize_app(cred)
    logger.info("Firebase Admin inicializado.")
except Exception as e:
    logger.warning(f"Advertencia: No se pudo cargar credenciales de Firebase ({e}).")
    # Inicialización Fallback (Permite decodificar tokens sin verificarlos contra el proyecto, útil en dev)
    try:
        firebase_admin.initialize_app()
    except Exception:
        pass


@router.post("/login", response_model=UserProfileReadV2)
async def login_with_firebase(
    request: LoginRequest, session: AsyncSession = Depends(get_session)
):
    """
    Recibe ID Token de Firebase, valida, obtiene/crea usuario en DB y devuelve perfil.
    """
    logger.info("Login endpoint invoked.")
    token = request.id_token
    uid = None
    email = None
    name = None
    picture = None

    # 1. Verificar Token
    try:
        # CRITICAL: auth.verify_id_token es SINCRONO y bloquea el event loop.
        # USAR SIEMPRE asyncio.to_thread para evitar timeouts en el servidor.
        decoded_token = await asyncio.to_thread(auth.verify_id_token, token)
        uid = decoded_token.get("uid")
        email = decoded_token.get("email")
        name = decoded_token.get("name")
        picture = decoded_token.get("picture")

        # Detectar Provider
        provider_str = decoded_token.get("firebase", {}).get("sign_in_provider")
        provider_map = {
            "google.com": ProviderType.GOOGLE,
            "apple.com": ProviderType.APPLE,
        }
        provider = provider_map.get(
            provider_str, ProviderType.GOOGLE
        )  # Fallback seguro a Google si no matchea (ej password)

        logger.info(
            f"Token verificado correctamente para UID: {uid} | Provider: {provider}"
        )

    except Exception as e:
        logger.error(f"Fallo verificación de token Firebase: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de autenticación inválido. Verifica tu sesión.",
        )

    if not uid or not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Token must contain uid and email",
        )

    # 2. Buscar usuario en DB
    # Buscamos por email para vincular con cuentas preexistentes.
    # TODO: Migrar a búsqueda por social_id para soporte multi-provider robusto.

    statement = select(User).where(User.email == email)
    results = await session.execute(statement)
    user = results.scalars().first()

    if user:
        # Actualizar datos si faltan
        changed = False
        if not user.full_name and name:
            user.full_name = name
            changed = True
        # if not user.photo_url and picture: ...

        # Si tuvieramos campo social_id, lo guardariamos:
        if hasattr(user, "social_id") and user.social_id != uid:
            user.social_id = uid
            changed = True

        if changed:
            session.add(user)
            await session.commit()
            await session.refresh(user)

    else:
        # Crear nuevo usuario
        logger.info(f"Creando nuevo usuario para: {email}")

        # Determinar provider (default: GOOGLE)

        user = User(
            email=email,
            full_name=name,
            social_id=uid,
            provider=provider,
            credits_available=0,
            is_admin=False,
            disabled=False,
        )

        session.add(user)
        await session.commit()
        await session.refresh(user)

    # Calculate credits dynamically
    now = datetime.now()
    credits_result = await session.execute(
        select(Credit).where(Credit.user_id == user.id)
    )
    credits = credits_result.scalars().all()
    balance = 0
    for c in credits:
        if c.amount < 0:
            balance += c.amount
        elif c.amount > 0 and (c.expires_at is None or c.expires_at > now):
            balance += c.amount

    logger.info(f"Login successful for user: {user.email}")
    return {
        "id": str(user.id),
        "full_name": user.full_name,
        "dni": user.dni,
        "email": user.email,
        "phone": user.phone,
        "is_admin": user.is_admin,
        "disabled": user.disabled,
        "is_trial": user.is_trial,
        "has_given_feedback": user.has_given_feedback,
        "feedback_sentiment": user.feedback_sentiment,
        "medical_certificate_url": user.medical_certificate_url,
        "credits_available": max(balance, 0),
    }


# -------------------------------------------------------------
# FCM TOKEN UPDATE
# -------------------------------------------------------------
class FCMTokenUpdate(BaseModel):
    token: Optional[str] = None


@router.patch("/me/fcm-token", response_model=UserProfileReadV2)
async def update_fcm_token(
    token_update: FCMTokenUpdate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    """
    Updates (or clears) the Firebase Cloud Messaging token for the current user.
    """
    current_user.fcm_token = token_update.token
    session.add(current_user)
    await session.commit()
    await session.refresh(current_user)

    # Calculate credits available (Copy logic from login for consistency)
    now = datetime.utcnow()
    query_credits = select(Credit).where(Credit.user_id == current_user.id)
    result_credits = await session.execute(query_credits)
    credits_db = result_credits.scalars().all()

    balance = 0
    for c in credits_db:
        if c.expires_at is None and c.amount > 0:
            balance += c.amount
        elif c.amount > 0 and (c.expires_at is None or c.expires_at > now):
            balance += c.amount

    return {
        "id": str(current_user.id),
        "full_name": current_user.full_name,
        "dni": current_user.dni,
        "email": current_user.email,
        "phone": current_user.phone,
        "is_admin": current_user.is_admin,
        "disabled": current_user.disabled,
        "is_trial": current_user.is_trial,
        "has_given_feedback": current_user.has_given_feedback,
        "feedback_sentiment": current_user.feedback_sentiment,
        "medical_certificate_url": current_user.medical_certificate_url,
        "credits_available": max(balance, 0),
    }
