import uuid
from datetime import datetime, timezone, time
from enum import Enum
from typing import List, Optional
from sqlalchemy import UniqueConstraint
from sqlmodel import Field, Relationship, SQLModel

"""
MODELS.PY
---------
Definición del esquema de base de datos usando SQLModel (SQLAlchemy + Pydantic).

Estrategias Clave:
1. ProviderType: Diferencia entre usuarios autenticados (Google/Apple) y usuarios "Sombra" (LOCAL) creados por admins.
2. Constraints: Se aplican restricciones únicas a nivel base de datos para garantizar integridad (ej. no duplicar DNI).
3. Soft Delete: El campo `is_deleted` marca registros como eliminados sin borrarlos físicamente, preservando historial.
"""


# ----------- ENUMS -----------
class BookingStatus(str, Enum):
    CONFIRMED = "confirmed"
    CANCELLED = "cancelled"


class ProviderType(str, Enum):
    GOOGLE = "GOOGLE"
    APPLE = "APPLE"
    MICROSOFT = "MICROSOFT"
    LOCAL = "LOCAL"  # Usuarios creados administrativamente (Shadow Users) sin login real hasta que reclaman la cuenta.


class DayOfWeek(str, Enum):
    MONDAY = "monday"
    TUESDAY = "tuesday"
    WEDNESDAY = "wednesday"
    THURSDAY = "thursday"
    FRIDAY = "friday"
    SATURDAY = "saturday"
    SUNDAY = "sunday"


# ----------- USER -----------
class User(SQLModel, table=True):
    __tablename__ = "users"
    __table_args__ = (
        UniqueConstraint("provider", "social_id", name="uq_provider_social_id"),
        UniqueConstraint("dni", name="uq_user_dni"),
    )

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    email: str = Field(index=True, unique=True)  # Shadow Users: dni@local.placeholder
    full_name: Optional[str] = Field(default=None, index=True)
    dni: Optional[str] = Field(default=None, index=True, unique=True)
    phone: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow, index=True)

    provider: ProviderType = Field()
    social_id: Optional[str] = Field(default=None, index=True)

    # Apto Físco
    medical_certificate_url: Optional[str] = Field(default=None)

    # Roles y Permisos
    is_admin: bool = Field(default=False)
    disabled: bool = Field(default=False)

    # Flag para usuarios con permisos restringidos (ej. clase de prueba)
    is_trial: bool = Field(default=False)

    # Feedback Feature
    # - has_given_feedback: True cuando el usuario ya respondió al popup de feedback
    # - feedback_sentiment: Guarda el tipo de respuesta ('positive' | 'negative')
    #   Usado para mostrar estadísticas en el panel de admin
    has_given_feedback: bool = Field(default=False)
    feedback_sentiment: Optional[str] = Field(default=None)

    # Push Notifications
    fcm_token: Optional[str] = Field(default=None, nullable=True)

    # Relaciones
    is_deleted: bool = Field(default=False)
    bookings: List["Booking"] = Relationship(back_populates="user")
    credits: List["Credit"] = Relationship(back_populates="user")
    fixed_schedules: List["FixedSchedule"] = Relationship(back_populates="user")


# ----------- INSTRUCTOR -----------
class Instructor(SQLModel, table=True):
    __tablename__ = "instructors"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    name: str = Field(index=True, unique=True)
    is_active: bool = Field(default=True)


# ----------- GYM CLASS -----------
class GymClass(SQLModel, table=True):
    __tablename__ = "gym_classes"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    name: str = Field(default="Clase")
    instructor: str = Field(index=True)
    start_time: datetime = Field(index=True)
    max_slots: int = Field(default=8)
    duration_minutes: int = Field(default=60)

    recurrence_group: Optional[uuid.UUID] = Field(default=None, index=True)
    recurrence: bool = Field(default=False)

    created_at: datetime = Field(default_factory=datetime.utcnow)
    cancelled_at: Optional[datetime] = None

    bookings: List["Booking"] = Relationship(back_populates="gym_class")


# ----------- BOOKING -----------
class Booking(SQLModel, table=True):
    __tablename__ = "bookings"
    __table_args__ = (
        # Integridad: Un usuario no puede tener dos reservas activas para la misma clase
        UniqueConstraint(
            "user_id", "gym_class_id", name="uq_prevent_double_booking_user"
        ),
    )

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    status: BookingStatus = Field(default=BookingStatus.CONFIRMED)
    assisted: bool = Field(default=False)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    cancelled_at: Optional[datetime] = None

    # Foreign Keys
    user_id: uuid.UUID = Field(foreign_key="users.id", index=True)
    gym_class_id: uuid.UUID = Field(foreign_key="gym_classes.id", index=True)

    user: User = Relationship(back_populates="bookings")
    gym_class: GymClass = Relationship(back_populates="bookings")


# ----------- FIXED SCHEDULE (ABONO FIJO) -----------
class FixedSchedule(SQLModel, table=True):
    __tablename__ = "fixed_schedules"
    __table_args__ = (
        UniqueConstraint(
            "user_id", "day_of_week", "start_time", name="uq_fixed_user_slot"
        ),
    )

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    day_of_week: DayOfWeek
    start_time: time = Field(index=True)

    user_id: uuid.UUID = Field(foreign_key="users.id", index=True)
    cancelled_at: Optional[datetime] = None

    user: User = Relationship(back_populates="fixed_schedules")


# ----------- CREDIT -----------
class Credit(SQLModel, table=True):
    __tablename__ = "credits"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    amount: int
    expires_at: Optional[datetime] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)

    user_id: uuid.UUID = Field(foreign_key="users.id", index=True)
    user: User = Relationship(back_populates="credits")


# ----------- SETTINGS -----------
class Setting(SQLModel, table=True):
    __tablename__ = "settings"

    key: str = Field(primary_key=True)
    value: str
    updated_at: datetime = Field(default_factory=datetime.utcnow)


# ----------- ANNOUNCEMENTS -----------
class Announcement(SQLModel, table=True):
    __tablename__ = "announcements"

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    title: Optional[str] = None  # Opcional
    content: Optional[str] = None  # Opcional

    image_url: Optional[str] = None
    # video_url eliminado - solo soportamos imágenes

    created_at: datetime = Field(default_factory=datetime.utcnow)
    expires_at: Optional[datetime] = None
