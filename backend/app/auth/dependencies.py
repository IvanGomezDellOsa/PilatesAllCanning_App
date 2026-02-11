# app/auth/dependencies.py
from fastapi import Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select
from app.database import get_session
from app.auth.firebase import verify_firebase_token
from app.models import User, ProviderType
from typing import Optional

from fastapi import Request


def get_token_from_header(request: Request) -> str:
    authorization: str = request.headers.get("Authorization", "")
    return authorization.replace("Bearer ", "")


async def get_current_user(
    token: str = Depends(get_token_from_header),
    session: AsyncSession = Depends(get_session),
) -> User:
    """
    Dependency principal:
    - Lee Bearer token manual (Firebase directo).
    - Valida con Firebase.
    - Busca o crea usuario (onboarding obliga full_name/dni).
    """
    if not token:
        raise HTTPException(status_code=401, detail="Falta el token de autorización")

    decoded = await verify_firebase_token(token)
    email: str = decoded.get("email")
    uid: str = decoded.get("uid")
    provider_str: Optional[str] = decoded.get("firebase", {}).get("sign_in_provider")

    if not email or not uid:
        raise HTTPException(401, detail="Token incompleto")

    provider_map = {
        "google.com": ProviderType.GOOGLE,
        "apple.com": ProviderType.APPLE,
    }
    provider = provider_map.get(provider_str)
    if not provider:
        raise HTTPException(401, detail="Provider no soportado")

    result = await session.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()

    if not user:
        user = User(
            email=email,
            full_name=None,  # Obliga onboarding
            dni=None,  # Obliga onboarding
            phone=None,
            provider=provider,
            social_id=uid,
            is_admin=False,
            disabled=False,
            # created_at usa default_factory aware en models.py → UTC correcto
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

    if user.disabled:
        raise HTTPException(401, detail="Usuario bloqueado")

    return user


async def get_current_user_optional(
    request: Request,
    session: AsyncSession = Depends(get_session),
) -> Optional[User]:
    """
    Dependency opcional: intenta obtener el usuario pero retorna None si falla.
    Útil para endpoints públicos que quieren comportamiento diferente para usuarios autenticados.
    """
    try:
        token = get_token_from_header(request)
        if not token:
            return None

        decoded = await verify_firebase_token(token)
        email: str = decoded.get("email")

        if not email:
            return None

        result = await session.execute(select(User).where(User.email == email))
        user = result.scalar_one_or_none()

        if user and not user.disabled:
            return user
        return None
    except Exception:
        return None


async def get_current_admin(
    current_user: User = Depends(get_current_user),
) -> User:
    if not current_user.is_admin:
        raise HTTPException(
            status_code=403, detail="No tienes permisos de administrador"
        )
    return current_user
