import firebase_admin
from firebase_admin import credentials, auth
from fastapi import HTTPException, status
import os
import asyncio

if not firebase_admin._apps:
    cred = credentials.Certificate(os.getenv("FIREBASE_SA_PATH"))
    firebase_admin.initialize_app(cred)


def _verify_token_sync(token: str) -> dict:
    """Synchronous wrapper for Firebase token verification."""
    return auth.verify_id_token(token, check_revoked=True)


async def verify_firebase_token(token: str) -> dict:
    """
    Valida el ID-Token de Firebase y devuelve el payload.
    Lanza 401 si el token es inválido o expiró.
    CRITICAL: auth.verify_id_token es SINCRONO — se ejecuta en thread pool.
    """
    try:
        return await asyncio.to_thread(_verify_token_sync, token)
    except auth.InvalidIdTokenError:
        raise HTTPException(401, "Token inválido")
    except auth.ExpiredIdTokenError:
        raise HTTPException(401, "Token expirado")
    except Exception as e:
        raise HTTPException(401, f"Error: {e}")

