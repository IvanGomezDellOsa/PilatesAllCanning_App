from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select
from app.models import Setting


async def get_setting_int(
    session: AsyncSession,
    key: str,
    default: int = 0,
) -> int:
    """
    Lee setting como int.
    Si no existe o no int → retorna default.
    """
    result = await session.execute(select(Setting.value).where(Setting.key == key))
    value = result.scalar_one_or_none()
    if value is None:
        return default
    try:
        return int(value)
    except ValueError:
        return default  # Valor inválido


async def get_setting_bool(
    session: AsyncSession,
    key: str,
    default: bool = False,
) -> bool:
    """Lee setting como bool (true/false lowercase)."""
    value = await session.scalar(select(Setting.value).where(Setting.key == key))
    if value is None:
        return default
    return value.lower() == "true"


import os
import smtplib
from email.message import EmailMessage
import logging
import asyncio

# Configuración de Email (Usar variables de entorno en producción)
SMTP_USER = os.getenv("SMTP_USER", "your_email@gmail.com")  # Email real removido para versión pública del repositorio
SMTP_PASS = os.getenv("SMTP_PASS", "")  # Requiere App Password de Google


def send_email_sync(subject: str, body: str, to_email: str):
    try:
        msg = EmailMessage()
        msg.set_content(body)
        msg["Subject"] = subject
        msg["From"] = SMTP_USER
        msg["To"] = to_email

        # Connect to Gmail SMTP
        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
            server.login(SMTP_USER, SMTP_PASS)
            server.send_message(msg)

        logging.info(f"[EMAIL] Sent to {to_email}: {subject}")
    except Exception as e:
        logging.error(f"[EMAIL ERROR] Failed to send: {e}")


async def send_email_background(subject: str, body: str, to_email: str):
    """Wrapper to run blocking SMTP call in a thread"""
    await asyncio.to_thread(send_email_sync, subject, body, to_email)
