from datetime import datetime
from typing import Optional
from pydantic import BaseModel
from app.models import BookingStatus

from typing import Any, Dict
import uuid


class GymClassRead(BaseModel):
    """
    DTO para la visualización de una clase en la grilla.
    Incluye estado calculado de cupos y relación con el usuario actual.
    """

    id: str
    name: str
    instructor: str
    start_time: datetime
    max_slots: int
    duration_minutes: int
    recurrence_group: Optional[str] = None

    # Datos calculados en tiempo de ejecución
    confirmed_count: int
    available_slots: int
    is_full: bool

    # Estado del usuario actual respecto a esta clase (para UI dinámica)
    # True if CONFIRMED, False otherwise
    my_status: bool = False

    class Config:
        from_attributes = True


class MyBookingRead(GymClassRead):
    """
    DTO extendido para el historial de reservas ('Mis Clases').
    Hereda datos de la clase y agrega metadatos específicos de la reserva.
    """

    booking_id: str
    status: BookingStatus
    cancelled_at: Optional[datetime] = None

    # Flag lógica para habilitar/deshabilitar botón de cancelar en UI
    # (True solo si es futura y está confirmada)
    can_cancel: bool


class BookingCreate(BaseModel):
    gym_class_id: str


class LoginRequest(BaseModel):
    id_token: str


class UserProfileReadV2(BaseModel):
    """
    Perfil público del usuario.
    Response model para /me y /login.
    """

    id: uuid.UUID
    full_name: Optional[str]
    dni: Optional[str]
    email: str
    phone: Optional[str]
    is_admin: bool
    disabled: bool
    is_trial: bool
    has_given_feedback: bool
    feedback_sentiment: Optional[str]  # 'positive' | 'negative' | None
    medical_certificate_url: Optional[str]
    credits_available: int

    class Config:
        from_attributes = True


class UserProfileUpdate(BaseModel):
    """
    DTO para actualizar el perfil del usuario.
    """

    full_name: Optional[str] = None
    dni: Optional[str] = None
    phone: Optional[str] = None


class GenericResponse(BaseModel):
    status: str
    message: Optional[str] = None
    data: Optional[Dict[str, Any]] = None


class CreditUpdate(BaseModel):
    amount: int
    expires_at: Optional[datetime] = None
    note: Optional[str] = None


class UserUpdate(BaseModel):
    email: Optional[str] = None
    full_name: Optional[str] = None
    dni: Optional[str] = None
    phone: Optional[str] = None
