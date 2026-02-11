import json
import logging
import asyncio
from typing import List, Optional
from firebase_admin import messaging
from sqlalchemy.future import select
from sqlalchemy.orm import Session
from sqlalchemy import text  # Moved from inner function
from app.database import engine
from app.models import User

logger = logging.getLogger(__name__)

MAX_PAYLOAD_SIZE = 4000  # 4KB Limit (with buffer)


async def send_multicast_notification(
    tokens: List[str], title: str, body: str, data: Optional[dict] = None
):
    """
    Envía notificaciones push a múltiples dispositivos (Multicast).
    - Valida el tamaño del payload (<4KB).
    - Maneja tokens inválidos eliminándolos de la DB.
    """
    if not tokens:
        logger.info("[NOTIFICATIONS] No tokens provided.")
        return

    # Payload Size Check & Truncation
    if len(body) > 1000:  # Initial soft check
        payload_preview = json.dumps({"title": title, "body": body, "data": data or {}})
        if len(payload_preview) > MAX_PAYLOAD_SIZE:
            logger.warning("[NOTIFICATIONS] Payload too large. Truncating body.")
            overhead = len(payload_preview) - len(body)
            allowed_body_len = MAX_PAYLOAD_SIZE - overhead - 100  # Buffer
            body = body[:allowed_body_len] + "..." if allowed_body_len > 0 else "Nuevo anuncio"

    success_count = 0
    failure_count = 0
    failed_tokens = []

    for i, token in enumerate(tokens):
        msg = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data=data or {},
            token=token,
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    channel_id="announcements_channel",
                    click_action="FLUTTER_NOTIFICATION_CLICK",
                ),
            ),
        )

        try:
            # CRITICAL: messaging.send es SINCRONO.
            # Envolver en asyncio.to_thread para no bloquear el loop principal durante el envío.
            await asyncio.to_thread(messaging.send, msg)
            success_count += 1
        except Exception as e:
            failure_count += 1
            err_str = str(e)
            logger.warning(f"[NOTIFICATIONS] Token failed: {err_str}")

            if (
                "registration-token-not-registered" in err_str
                or "not-found" in err_str
                or "invalid-argument" in err_str
            ):
                failed_tokens.append(token)

    logger.info(
        f"[NOTIFICATIONS] Batch result: {success_count} success, {failure_count} failure."
    )

    if failed_tokens:
        await _handle_failed_tokens_manual(failed_tokens)


async def _handle_failed_tokens_manual(tokens_to_remove: List[str]):
    """Elimina tokens inválidos de la base de datos."""
    if tokens_to_remove:
        logger.info(
            f"[NOTIFICATIONS] Removing {len(tokens_to_remove)} invalid tokens from DB."
        )

        async with engine.begin() as conn:
            if len(tokens_to_remove) == 1:
                await conn.execute(
                    text("UPDATE users SET fcm_token = NULL WHERE fcm_token = :token"),
                    {"token": tokens_to_remove[0]},
                )
            else:
                await conn.execute(
                    text("UPDATE users SET fcm_token = NULL WHERE fcm_token IN :tokens"),
                    {"tokens": tuple(tokens_to_remove)},
                )

