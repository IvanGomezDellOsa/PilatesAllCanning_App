import shutil
import os
from pathlib import Path as FilePath
from io import BytesIO
import asyncio
from PIL import Image as PILImage  # Para compresión de imágenes
from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    Path,
    Body,
    Query,
    File,
    UploadFile,
    Form,
    Request,
    BackgroundTasks,
)
from app.notifications import send_multicast_notification
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError
from sqlmodel import select, func
from typing import Optional, List
from datetime import datetime, timedelta, timezone, time
from uuid import uuid4, UUID

from app.database import get_session
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from app.models import (
    GymClass,
    Instructor,
    Booking,
    BookingStatus,
    User,
    Setting,
    Credit,
    FixedSchedule,
    DayOfWeek,
    Announcement,
    ProviderType,
)
from app.auth.dependencies import get_current_admin
from app.api.schemas import CreditUpdate, UserUpdate
import logging

"""
ADMIN ENDPOINTS (adminEP.py)
----------------------------
Gestión centralizada para administradores.

Funcionalidades Principales:
1. Gestión de Clases: Crear clases únicas o series recurrentes (con lógica de Feriados).
2. Reservas: Visualizar y cancelar reservas de alumnos.
3. Usuarios: ABM completo de usuarios (incluyendo Notas y Certificados).

Notas de Implementación:
- Las series recurrentes (recurrence=True) generan múltiples instancias de `GymClass`.
- Si una instancia cae en un feriado (HOLIDAYS_2026), se asigna `cancelled_at` automáticamente
  y se reembolsan los créditos a los usuarios con Abono Fijo afectados.
"""

logger = logging.getLogger("uvicorn")

router = APIRouter(dependencies=[Depends(get_current_admin)])


# Mapa para convertir int de python (0=Monday) a Enum
INT_TO_DAY_MAP = {
    0: DayOfWeek.MONDAY,
    1: DayOfWeek.TUESDAY,
    2: DayOfWeek.WEDNESDAY,
    3: DayOfWeek.THURSDAY,
    4: DayOfWeek.FRIDAY,
    5: DayOfWeek.SATURDAY,
    6: DayOfWeek.SUNDAY,
}

# Feriados Inamovibles 2026-2027 (Argentina)
HOLIDAYS_2026 = {
    # 2026
    "2026-01-01",
    "2026-02-16",
    "2026-02-17",
    "2026-03-24",
    "2026-04-02",
    "2026-04-03",
    "2026-05-01",
    "2026-05-25",
    "2026-06-20",
    "2026-07-09",
    "2026-08-17",
    "2026-10-12",
    "2026-11-23",
    "2026-12-08",
    "2026-12-25",
    # 2027
    "2027-01-01",
    "2027-02-08",
    "2027-02-09",
    "2027-03-24",
    "2027-03-26",
    "2027-04-02",
    "2027-05-01",
    "2027-05-25",
    "2027-06-20",
    "2027-07-09",
    "2027-12-08",
    "2027-12-25",
}

# ----------- GYM CLASSES -----------


@router.post("/gym-classes", status_code=201)
async def create_gym_class(
    name: str = Body("Clase", embed=True),
    instructor: str = Body(..., embed=True),
    start_time: datetime = Body(..., embed=True),
    max_slots: int = Body(8, embed=True),
    duration_minutes: int = Body(60, embed=True),
    recurrence: bool = Body(False, embed=True),
    session: AsyncSession = Depends(get_session),
):
    """
    Crea clase individual o serie recurrente.
    Realiza auto-booking buscando coincidencias en FixedSchedules.
    """
    today = datetime.now()
    if start_time <= today:
        raise HTTPException(
            400, detail="El horario ya ha pasado. Elija una hora futura."
        )

    # Convert to naive UTC for DB compatibility
    start_time = start_time.replace(tzinfo=None)

    instr = await session.scalar(
        select(Instructor).where(
            Instructor.name == instructor, Instructor.is_active == True
        )
    )
    if not instr:
        # raise HTTPException(400, detail="Instructor no encontrado o inactivo")
        # FIX: Si no existe, lo creamos automáticamente para evitar error 400
        instr = Instructor(name=instructor, is_active=True)
        session.add(instr)
        await session.commit()
        await session.refresh(instr)

    recurrence_group = uuid4() if recurrence else None
    weeks = 12 if recurrence else 1
    created_classes = []

    current_time = start_time
    for i in range(weeks):
        gym_class = GymClass(
            name=name,
            instructor=instructor,
            start_time=current_time,
            max_slots=max_slots,
            duration_minutes=duration_minutes,
            recurrence=recurrence if i == 0 else False,
            recurrence_group=recurrence_group,
        )
        session.add(gym_class)
        created_classes.append(gym_class)
        current_time += timedelta(weeks=1)

    await session.commit()
    for c in created_classes:
        await session.refresh(c)

    # Auto-booking de abonos fijos
    bookings_created = 0
    refunds_given = 0

    for gym_class in created_classes:
        day_num = gym_class.start_time.weekday()
        target_day_enum = INT_TO_DAY_MAP[day_num]
        class_time = gym_class.start_time.time()

        # Check if it is holiday
        date_str = gym_class.start_time.strftime("%Y-%m-%d")
        is_holiday = date_str in HOLIDAYS_2026

        # Buscar abonos fijos activos para este día y hora
        logger.info(
            f"[AUTO-BOOKING] Searching fixed schedules for day={target_day_enum.value}, time={class_time}"
        )
        fixed_matches = await session.execute(
            select(FixedSchedule)
            .join(User)
            .where(
                FixedSchedule.cancelled_at.is_(None),
                FixedSchedule.day_of_week == target_day_enum,
                FixedSchedule.start_time == class_time,
                User.is_deleted == False,
            )
        )
        fixed_list = fixed_matches.scalars().all()
        logger.info(f"[AUTO-BOOKING] Found {len(fixed_list)} fixed schedules matching")

        for fixed in fixed_list:

            # HOLIDAY LOGIC: Si es feriado, devolvemos crédito y NO reservamos
            if is_holiday:
                # Crear crédito de reembolso
                refund_credit = Credit(amount=1, user_id=fixed.user_id)
                session.add(refund_credit)
                refunds_given += 1
                user = await session.get(User, fixed.user_id)
                logger.info(
                    f"[HOLIDAY] Refunded 1 credit to user {user.email if user else fixed.user_id} for {date_str} (Class skipped)"
                )
                continue

            # Evitar duplicados si ya existe reserva manual
            existing = await session.scalar(
                select(Booking).where(
                    Booking.gym_class_id == gym_class.id,
                    Booking.user_id == fixed.user_id,
                )
            )
            if existing:
                continue

            booking = Booking(
                user_id=fixed.user_id,
                gym_class_id=gym_class.id,
                status=BookingStatus.CONFIRMED,
            )
            session.add(booking)
            bookings_created += 1

    if bookings_created > 0 or refunds_given > 0:
        await session.commit()

    # Return the first class as a properly formatted dict
    first_class = created_classes[0]
    return {
        "id": str(first_class.id),
        "name": first_class.name,
        "instructor": first_class.instructor,
        "start_time": first_class.start_time,
        "max_slots": first_class.max_slots,
        "duration_minutes": first_class.duration_minutes,
        "confirmed_count": 0,
        "my_status": False,
        "recurrence": first_class.recurrence,
        "recurrence_group": (
            str(first_class.recurrence_group) if first_class.recurrence_group else None
        ),
    }


@router.patch("/gym-classes/{class_id}")
async def update_gym_class(
    class_id: str = Path(...),
    name: Optional[str] = Body(None),
    instructor: Optional[str] = Body(None),
    max_slots: Optional[int] = Body(None),
    duration_minutes: Optional[int] = Body(None),
    session: AsyncSession = Depends(get_session),
):
    gym_class = await session.get(GymClass, class_id)
    if not gym_class:
        raise HTTPException(404, detail="Clase no encontrada")

    if name is not None:
        gym_class.name = name
    if max_slots is not None:
        gym_class.max_slots = max_slots
    if duration_minutes is not None:
        gym_class.duration_minutes = duration_minutes

    if instructor is not None:
        instr = await session.scalar(
            select(Instructor).where(
                Instructor.name == instructor, Instructor.is_active == True
            )
        )
        if not instr:
            raise HTTPException(400, detail="Instructor no encontrado o inactivo")
        gym_class.instructor = instructor

    session.add(gym_class)
    await session.commit()
    await session.refresh(gym_class)
    return gym_class


@router.get("/gym-classes/{class_id}")
async def get_gym_class_detail(
    class_id: str = Path(...),
    session: AsyncSession = Depends(get_session),
):
    gym_class = await session.get(GymClass, class_id)
    if not gym_class:
        raise HTTPException(404, detail="Clase no encontrada")

    bookings = await session.execute(
        select(Booking, User.full_name)
        .join(User)
        .where(Booking.gym_class_id == class_id)
        .where(Booking.status == BookingStatus.CONFIRMED)  # Hide cancelled bookings
    )
    bookings_list = []
    for b in bookings:
        booking = b.Booking
        user_name = b.full_name or "Sin nombre"

        bookings_list.append(
            {
                "bookingId": str(booking.id),
                "classId": str(gym_class.id),
                "name": gym_class.name,
                "instructor": gym_class.instructor,
                "userName": user_name,
                "startTime": gym_class.start_time,
                "status": booking.status.value,
            }
        )

    confirmed_count = await session.scalar(
        select(func.count(Booking.id)).where(
            Booking.gym_class_id == class_id, Booking.status == BookingStatus.CONFIRMED
        )
    )

    # Return flattened structure to match Frontend GymClassDetail
    return {
        "id": str(gym_class.id),
        "name": gym_class.name,
        "instructor": gym_class.instructor,
        "start_time": gym_class.start_time,
        "duration_minutes": gym_class.duration_minutes,
        "max_slots": gym_class.max_slots,
        "bookings": bookings_list,
        "confirmed_count": confirmed_count,
        # recurrence info if needed...
        "status": "ok",  # Extra safety
    }


@router.post("/gym-classes/{class_id}/manual-book")
async def manual_book(
    class_id: str = Path(...),
    # Opción A: Usuario existente seleccionado
    user_id: Optional[str] = Body(None, embed=True),
    # Opción B: Datos para crear usuario sombra
    dni: Optional[str] = Body(None, embed=True),
    full_name: Optional[str] = Body(None, embed=True),
    is_trial: bool = Body(False, embed=True),  # Configurable por Admin
    session: AsyncSession = Depends(get_session),
):
    """
    Reserva manual por Admin.
    Si se provee DNI y no existe usuario, crea un 'Shadow User' automáticamente.
    """
    gym_class = await session.get(GymClass, class_id)
    if not gym_class:
        raise HTTPException(404, detail="Clase no encontrada")

    target_user = None

    # Lógica de resolución de usuario
    if user_id:
        target_user = await session.get(User, user_id)
        if not target_user:
            raise HTTPException(404, detail="Usuario no encontrado")

    elif dni:
        dni = dni.strip()
        # Buscar existencia previa por DNI
        result = await session.execute(select(User).where(User.dni == dni))
        target_user = result.scalar_one_or_none()

        # Si no existe por DNI, verificar por Email generado (Safety check)
        if not target_user:
            generated_email = f"{dni}@local.placeholder"
            result_email = await session.execute(
                select(User).where(User.email == generated_email)
            )
            target_user = result_email.scalar_one_or_none()

        # Si no existe, crear Shadow User
        if not target_user:
            if not full_name:
                raise HTTPException(400, detail="Nombre requerido para usuario nuevo")

            target_user = User(
                email=f"{dni}@local.placeholder",  # Email interno único
                full_name=full_name,
                dni=dni,
                provider=ProviderType.LOCAL,
                social_id=f"local_{dni}",  # Ensure uniqueness for (provider, social_id)
                is_trial=is_trial,
                is_admin=False,
            )
            session.add(target_user)
            try:
                await session.commit()
                await session.refresh(target_user)
            except IntegrityError:
                await session.rollback()
                raise HTTPException(
                    400, detail="Error creando usuario. DNI posiblemente duplicado."
                )

    if not target_user:
        raise HTTPException(400, detail="Faltan datos de usuario")

    # Validación de Cupos
    confirmed_count = await session.scalar(
        select(func.count(Booking.id)).where(
            Booking.gym_class_id == class_id, Booking.status == BookingStatus.CONFIRMED
        )
    )
    if confirmed_count >= gym_class.max_slots:
        raise HTTPException(400, detail="La clase está completa (0 cupos disponibles)")

    # Validación de negocio
    existing = await session.scalar(
        select(Booking).where(
            Booking.user_id == target_user.id, Booking.gym_class_id == class_id
        )
    )
    if existing:
        if existing.status == BookingStatus.CONFIRMED:
            raise HTTPException(400, detail="Usuario ya inscripto en esta clase")

        # Si estaba cancelada, REACTIVAR
        existing.status = BookingStatus.CONFIRMED
        existing.cancelled_at = None
        session.add(existing)
        await session.commit()
        return {"status": "booked (reactivated)", "user_created": user_id is None}

    # Crear reserva
    booking = Booking(
        user_id=target_user.id, gym_class_id=class_id, status=BookingStatus.CONFIRMED
    )
    session.add(booking)
    await session.commit()

    return {"status": "booked", "user_created": user_id is None}


@router.delete("/gym-classes/{class_id}")
async def delete_gym_class(
    class_id: str = Path(...),
    cancel_series: bool = Query(False, description="Si true, cancela serie futuras"),
    session: AsyncSession = Depends(get_session),
):
    """
    Cancela clase o serie futuras (soft-delete).
    Cancela bookings CONFIRMED asociados + reembolso crédito (reservas normales).
    """
    gym_class = await session.get(GymClass, class_id)
    if not gym_class:
        raise HTTPException(404, detail="Clase no encontrada")
    if gym_class.cancelled_at:
        raise HTTPException(400, detail="Clase ya cancelada")

    now = datetime.utcnow()
    class_ids = [class_id]

    if cancel_series and gym_class.recurrence_group:
        future_classes = await session.execute(
            select(GymClass.id).where(
                GymClass.recurrence_group == gym_class.recurrence_group,
                GymClass.start_time > now,
                GymClass.cancelled_at.is_(None),  # Solo activas
            )
        )
        class_ids = [str(c) for c in future_classes.scalars().all()]

    cancelled_count = 0
    refunded_count = 0
    for cid in class_ids:
        to_cancel = await session.get(GymClass, cid)
        to_cancel.cancelled_at = now
        session.add(to_cancel)
        cancelled_count += 1

        # Cancelar bookings CONFIRMED + reembolso (reservas normales)
        bookings = await session.execute(
            select(Booking).where(
                Booking.gym_class_id == cid, Booking.status == BookingStatus.CONFIRMED
            )
        )
        for b in bookings.scalars().all():
            b.status = BookingStatus.CANCELLED
            b.cancelled_at = now
            session.add(b)

            # Reembolso solo si es cancelación individual (NO serie completa)
            if b.user_id and not cancel_series:
                refund = Credit(amount=1, user_id=b.user_id)
                session.add(refund)
                refunded_count += 1

    await session.commit()
    return {
        "status": "cancelled",
        "classes_cancelled": cancelled_count,
        "credits_refunded": refunded_count,
    }


# ----------- FIXED SCHEDULES -----------
@router.post("/fixed-schedules", status_code=201)
async def add_fixed_schedule(
    # Opción A: Usuario existente
    user_id: Optional[str] = Body(None, embed=True),
    # Opción B: Crear Sombra
    dni: Optional[str] = Body(None, embed=True),
    full_name: Optional[str] = Body(None, embed=True),
    day_of_week: DayOfWeek = Body(..., embed=True),
    start_time: time = Body(..., embed=True),
    session: AsyncSession = Depends(get_session),
):
    """
    Crea abono fijo.
    Si el usuario no existe, crea un Shadow User.
    Genera reservas automáticamente para clases futuras (Backfill).
    """
    target_user = None

    # Resolución de usuario (Idéntica a manual_book)
    if user_id:
        target_user = await session.get(User, user_id)
        if not target_user:
            raise HTTPException(404, detail="Usuario no encontrado")
    elif dni:
        result = await session.execute(select(User).where(User.dni == dni))
        target_user = result.scalar_one_or_none()

        if not target_user:
            if not full_name:
                raise HTTPException(400, detail="Nombre requerido para usuario nuevo")

            target_user = User(
                email=f"{dni}@local.placeholder",
                full_name=full_name,
                dni=dni,
                provider=ProviderType.LOCAL,
                social_id=f"local_{dni}",
                is_trial=False,  # Abonos fijos suelen ser alumnos regulares
            )
            session.add(target_user)
            try:
                await session.commit()
                await session.refresh(target_user)
            except IntegrityError:
                await session.rollback()
                raise HTTPException(400, detail="Error creando usuario.")

    if not target_user:
        raise HTTPException(400, detail="Faltan datos de usuario")

    # Verificar si ya existe un fixed schedule (incluso cancelado) para evitar duplicados
    existing_schedule = await session.scalar(
        select(FixedSchedule).where(
            FixedSchedule.user_id == target_user.id,
            FixedSchedule.day_of_week == day_of_week,
            FixedSchedule.start_time == start_time,
        )
    )

    if existing_schedule:
        # Si existe pero está cancelado, reactivarlo
        if existing_schedule.cancelled_at:
            existing_schedule.cancelled_at = None
            session.add(existing_schedule)
            await session.commit()
            fixed = existing_schedule
        else:
            # Ya existe un schedule activo
            raise HTTPException(
                400, detail="Este usuario ya tiene un turno fijo en este horario"
            )
    else:
        # Crear nuevo Fixed Schedule
        fixed = FixedSchedule(
            day_of_week=day_of_week,
            start_time=start_time,
            user_id=target_user.id,
        )
        session.add(fixed)
        await session.commit()  # Commit inicial para tener ID del fixed

    # Backfill: Reservar clases futuras coincidentes
    now = datetime.now()
    weekday_map = {
        "monday": 0,
        "tuesday": 1,
        "wednesday": 2,
        "thursday": 3,
        "friday": 4,
        "saturday": 5,
        "sunday": 6,
    }
    target_weekday = weekday_map[day_of_week.value]

    future_classes = await session.execute(
        select(GymClass).where(GymClass.start_time > now)
    )
    bookings_created = 0

    for gym_class in future_classes.scalars().all():
        if gym_class.start_time.weekday() != target_weekday:
            continue
        class_time = gym_class.start_time.time()
        if class_time.hour != start_time.hour or class_time.minute != start_time.minute:
            continue

        existing = await session.scalar(
            select(Booking).where(
                Booking.gym_class_id == gym_class.id, Booking.user_id == target_user.id
            )
        )
        if existing:
            continue

        booking = Booking(
            user_id=target_user.id,
            gym_class_id=gym_class.id,
            status=BookingStatus.CONFIRMED,
        )
        session.add(booking)
        bookings_created += 1

    await session.commit()
    return {
        "fixed_schedule": fixed,
        "message": f"Regla creada y {bookings_created} clases futuras reservadas.",
    }


@router.delete("/fixed-schedules/{schedule_id}")
async def delete_fixed_schedule(
    schedule_id: str = Path(...),
    session: AsyncSession = Depends(get_session),
):
    """
    Cancela un turno fijo y todas sus reservas futuras asociadas.
    Devuelve crédito por cada reserva cancelada.
    """
    fixed = await session.get(FixedSchedule, schedule_id)
    if not fixed:
        raise HTTPException(404, detail="Turno fijo no encontrado")
    if fixed.cancelled_at:
        raise HTTPException(400, detail="Turno fijo ya cancelado")

    now = datetime.now()

    # Soft-delete del turno fijo
    fixed.cancelled_at = now
    session.add(fixed)

    # Buscar todas las reservas futuras que coincidan con el horario del turno fijo
    # Buscamos clases futuras que coincidan con día y hora
    future_classes = await session.execute(
        select(GymClass).where(
            GymClass.start_time > now, GymClass.cancelled_at.is_(None)
        )
    )

    cancelled_count = 0
    refunded_count = 0

    for gym_class in future_classes.scalars().all():
        # Verificar si coincide día y hora
        class_day = gym_class.start_time.weekday()
        class_time = gym_class.start_time.time()
        target_day_enum = INT_TO_DAY_MAP[class_day]

        if target_day_enum != fixed.day_of_week or class_time != fixed.start_time:
            continue

        # Buscar booking del usuario para esta clase
        booking = await session.scalar(
            select(Booking).where(
                Booking.gym_class_id == gym_class.id,
                Booking.user_id == fixed.user_id,
                Booking.status == BookingStatus.CONFIRMED,
            )
        )

        if booking:
            booking.status = BookingStatus.CANCELLED
            booking.cancelled_at = now
            session.add(booking)
            cancelled_count += 1

            # Reembolso de crédito
            refund = Credit(amount=1, user_id=fixed.user_id)
            session.add(refund)
            refunded_count += 1

    await session.commit()
    return {
        "status": "cancelled",
        "bookings_cancelled": cancelled_count,
        "credits_refunded": refunded_count,
    }


# ----------- INSTRUCTORS -----------


@router.post("/instructors", status_code=201)
async def create_instructor(
    name: str = Body(..., embed=True),
    session: AsyncSession = Depends(get_session),
):
    instructor = Instructor(name=name, is_active=True)
    session.add(instructor)
    try:
        await session.commit()
        await session.refresh(instructor)
        return instructor
    except IntegrityError:
        await session.rollback()
        raise HTTPException(400, detail="Ya existe un instructor con ese nombre")



@router.get("/instructors")
async def get_instructors(
    session: AsyncSession = Depends(get_session),
):
    """
    Obtiene la lista completa de instructores.
    """
    result = await session.execute(select(Instructor).order_by(Instructor.name))
    return result.scalars().all()


@router.delete("/instructors/{instructor_id}")
async def delete_instructor(
    instructor_id: str = Path(..., description="ID del instructor a eliminar"),
    session: AsyncSession = Depends(get_session),
):
    """
    Elimina permanentemente un instructor de la base de datos (Hard Delete).

    Verifica la existencia del instructor antes de eliminarlo y realiza una
    comprobación posterior para asegurar que la transacción se haya completado
    correctamente.
    """
    # 1. Verificar existencia
    instr = await session.get(Instructor, instructor_id)
    if not instr:
        raise HTTPException(404, detail="Instructor no encontrado")

    try:
        # 2. Ejecutar Hard Delete
        # Utilizamos delete explícito de la sesión para asegurar la eliminación física
        await session.delete(instr)
        await session.commit()

        # 3. Verificación de Integridad (Opcional pero recomendada para depuración)
        # Intentamos recuperar el registro nuevamente para confirmar su eliminación.
        # Nota: En sistemas de alta concurrencia esto podría ser redundante,
        # pero ayuda a confirmar que no hubo locks o rollbacks silenciosos.
        check = await session.get(Instructor, instructor_id)
        if check:
            # Si el registro persiste, algo falló en la transacción
            logger.error(f"[DELETE] Falló la eliminación física del instructor {instructor_id}")
            # Se podría intentar un fallback con SQL directo si fuera crítico
        else:
            logger.info(f"[DELETE] Instructor {instructor_id} eliminado correctamente.")

    except Exception as e:
        logger.error(f"Error eliminando instructor: {e}")
        await session.rollback()
        raise e

    return {"status": "deleted"}



# ----------- GESTIÓN DE USUARIOS (TODOS) -----------


@router.get("/users")
async def search_users(
    request: Request,
    q: Optional[str] = Query(
        None, description="Busca por nombre o DNI (case insensitive)"
    ),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    session: AsyncSession = Depends(get_session),
):
    """
    Lista usuarios con buscador y paginación.
    Retorna usuario + flag is_instructor.
    """
    # Usamos outer join con Instructor para saber si es instructor activo
    # Optimización: eager loading de creditos para evitar N+1
    statement = (
        select(User)
        .options(selectinload(User.credits))
        .order_by(User.full_name)
        .offset(skip)
        .limit(limit)
    )

    if q:
        statement = statement.where(
            (User.full_name.ilike(f"%{q}%")) | (User.dni.ilike(f"%{q}%"))
        ).where(User.is_deleted == False)
    else:
        statement = statement.where(User.is_deleted == False)

    result = await session.execute(statement)

    # Mapeamos a lista de dicts
    output = []
    now = datetime.now()

    for user in result.scalars().all():
        data = user.model_dump()  # Convert SQLModel to dict

        # Build absolute URL for medical certificate
        cert_url = data.get("medical_certificate_url")
        if cert_url and not cert_url.startswith("http"):
            base_url = str(request.base_url)
            if base_url.endswith("/"):
                data["medical_certificate_url"] = f"{base_url}{cert_url}"
            else:
                data["medical_certificate_url"] = f"{base_url}/{cert_url}"

        # Cleaned up: No more 'is_instructor' logic here

        # Calcular créditos (En memoria, ya cargados por selectinload)
        credits = user.credits
        balance = 0
        for c in credits:
            if c.amount < 0:
                balance += c.amount
            elif c.amount > 0 and (c.expires_at is None or c.expires_at > now):
                balance += c.amount

        data["credits_available"] = max(balance, 0)
        output.append(data)

    return output


@router.get("/users/{user_id}")
async def get_user_detail(
    request: Request,
    user_id: str = Path(...),
    session: AsyncSession = Depends(get_session),
):
    """Ficha usuario: info + créditos disponibles + status instructor."""
    user = await session.get(User, user_id)
    if not user:
        raise HTTPException(404, detail="Usuario no encontrado")

    now = datetime.now()
    credits = await session.execute(select(Credit).where(Credit.user_id == user_id))
    available = sum(
        c.amount
        for c in credits.scalars().all()
        if c.amount > 0 and (c.expires_at is None or c.expires_at > now)
    )

    return {
        **user.model_dump(),
        "credits_available": max(available, 0),
        "is_instructor_active": False,  # Deprecated
    }


@router.patch("/users/{user_id}/toggle-disabled")
async def toggle_user_disabled(
    user_id: str = Path(...),
    session: AsyncSession = Depends(get_session),
):
    """
    Switch Bloquear/Desbloquear Acceso.
    Si se bloquea (disabled=True), se cancelan todas las reservas FUTURAS.
    """
    user = await session.get(User, user_id)
    if not user:
        raise HTTPException(404, detail="Usuario no encontrado")

    new_state = not user.disabled
    user.disabled = new_state
    
    if new_state:  # Si estamos bloqueando
        now = datetime.now()
        # Buscar reservas futuras y confirmadas
        future_bookings_result = await session.execute(
            select(Booking)
            .join(GymClass)
            .where(
                Booking.user_id == user.id,
                Booking.status == BookingStatus.CONFIRMED,
                GymClass.start_time > now,
            )
        )
        bookings_to_cancel = future_bookings_result.scalars().all()
        
        for b in bookings_to_cancel:
            b.status = BookingStatus.CANCELLED
            b.cancelled_at = now
            session.add(b)
            
        logger.info(f"User {user_id} blocked. Cancelled {len(bookings_to_cancel)} future bookings.")

    session.add(user)
    await session.commit()
    return {"status": "updated", "disabled": user.disabled}





@router.patch("/users/{user_id}/details")
async def update_user_details(
    user_id: str = Path(...),
    details: UserUpdate = Body(...),
    session: AsyncSession = Depends(get_session),
):
    """Actualiza detalles del usuario (email, nombre, DNI, teléfono)."""
    user = await session.get(User, user_id)
    if not user:
        raise HTTPException(404, detail="Usuario no encontrado")

    if details.email is not None:
        user.email = details.email
    if details.full_name is not None:
        user.full_name = details.full_name
    if details.dni is not None:
        user.dni = details.dni
    if details.phone is not None:
        user.phone = details.phone

    try:
        session.add(user)
        await session.commit()
        await session.refresh(user)
        return {"status": "updated", "user": user}
    except IntegrityError:
        await session.rollback()
        raise HTTPException(
            400, detail="El email o DNI ya están en uso por otro usuario"
        )


# NOTA: Endpoint de créditos movido a línea ~775 como add_user_credits() con soporte para negativos


# ----------- SETTINGS (ADMIN) -----------
@router.patch("/settings/{key}")
async def update_setting(
    key: str = Path(...),
    value: str = Body(..., embed=True),
    session: AsyncSession = Depends(get_session),
):
    """
    Admin actualiza configuraciones globales.
    Ejemplos: cancel_minutes_before, address, whatsapp, instagram.
    """
    setting = await session.get(Setting, key)
    if not setting:
        setting = Setting(key=key)
    setting.value = value
    setting.updated_at = datetime.now()
    session.add(setting)
    await session.commit()
    return {"status": "updated", "key": key, "value": value}


# ----------- BOOKING MANAGEMENT (ADMIN) -----------


@router.delete("/bookings/{booking_id}")
async def admin_cancel_booking(
    booking_id: str = Path(...),
    session: AsyncSession = Depends(get_session),
):
    """
    Admin cancela reserva de cualquier usuario.
    Siempre devuelve crédito si era usuario registrado.
    """
    booking = await session.get(Booking, booking_id)
    if not booking:
        raise HTTPException(404, detail="Reserva no encontrada")

    if booking.status != BookingStatus.CONFIRMED:
        raise HTTPException(400, detail="La reserva no está confirmada")

    now = datetime.now()
    booking.status = BookingStatus.CANCELLED
    booking.cancelled_at = now
    session.add(booking)

    # Reembolso forzado por ser acción admin
    if booking.user_id:
        refund = Credit(amount=1, user_id=booking.user_id)
        session.add(refund)
        logger.info(f"[ADMIN] Cancelled booking {booking_id} (Refunded)")

    await session.commit()
    return {"status": "cancelled", "refunded": True}


# ----------- USER BOOKINGS (ADMIN) -----------


@router.get("/users/{user_id}/bookings")
async def get_user_bookings(
    user_id: str = Path(...),
    session: AsyncSession = Depends(get_session),
):
    """
    Obtiene todas las reservas (pasadas y futuras) de un usuario.
    Ordenadas por fecha descendente.
    """
    user = await session.get(User, user_id)
    if not user:
        raise HTTPException(404, detail="Usuario no encontrado")

    bookings = await session.execute(
        select(Booking, GymClass)
        .join(GymClass)
        .where(Booking.user_id == user_id)
        .order_by(GymClass.start_time.desc())
    )

    results = []
    for b, gc in bookings:
        # Busca instructor nombre
        # Nota: En un sistema real mas complejo podria ser un join mas,
        # pero aqui `gc.instructor` es un string en GymClass
        results.append(
            {
                "id": str(b.id),
                "status": b.status,
                "gym_class": {
                    "id": str(gc.id),
                    "name": gc.name,
                    "instructor": gc.instructor,
                    "start_time": gc.start_time.isoformat(),
                    "duration_minutes": gc.duration_minutes,
                },
            }
        )

    return results


@router.get("/users/{user_id}/fixed-schedules")
async def get_user_fixed_schedules(
    user_id: str = Path(...),
    session: AsyncSession = Depends(get_session),
):
    """
    Obtiene todos los turnos fijos activos de un usuario.
    """
    user = await session.get(User, user_id)
    if not user:
        raise HTTPException(404, detail="Usuario no encontrado")

    schedules = await session.execute(
        select(FixedSchedule)
        .where(FixedSchedule.user_id == user_id, FixedSchedule.cancelled_at.is_(None))
        .order_by(FixedSchedule.day_of_week, FixedSchedule.start_time)
    )

    results = []
    for schedule in schedules.scalars().all():
        results.append(
            {
                "id": str(schedule.id),
                "day_of_week": schedule.day_of_week.value,
                "start_time": schedule.start_time.isoformat(),
            }
        )

    return results


@router.post("/users", status_code=201)
async def create_user(
    full_name: str = Body(..., embed=True),
    dni: str = Body(..., embed=True),
    is_instructor: bool = Body(False, embed=True),  # Deprecated, ignored

    is_trial: bool = Body(False, embed=True),
    session: AsyncSession = Depends(get_session),
):
    """
    Crea un usuario "ghost" (local/shadow) sin autenticación.
    Usado por admin para crear usuarios que no tienen cuenta Google/Apple.
    """
    # Verificar si ya existe un usuario con este DNI
    existing = await session.scalar(select(User).where(User.dni == dni))
    if existing:
        raise HTTPException(400, detail="Ya existe un usuario con este DNI")

    # Crear usuario shadow
    user = User(
        email=f"{dni}@local.placeholder",
        full_name=full_name,
        dni=dni,
        provider=ProviderType.LOCAL,
        social_id=f"local_{dni}",
        is_trial=is_trial,
        is_admin=False,
    )
    session.add(user)
    await session.commit()
    await session.refresh(user)

    # Is_instructor logic removed


    return {
        "id": str(user.id),
        "email": user.email,
        "full_name": user.full_name,
        "dni": user.dni,
        "is_trial": user.is_trial,
        "is_instructor": False,

    }


# ----------- AJUSTES (TOGGLE ADMIN) -----------
@router.patch("/users/{user_id}/toggle-admin")
async def toggle_user_admin(
    user_id: str = Path(...),
    session: AsyncSession = Depends(get_session),
):
    """Switch Hacer Admin (toggle is_admin)."""
    user = await session.get(User, user_id)
    if not user:
        raise HTTPException(404, detail="Usuario no encontrado")

    user.is_admin = not user.is_admin
    session.add(user)
    await session.commit()
    return {"status": "updated", "is_admin": user.is_admin}


@router.post("/users/{user_id}/credits")
async def add_user_credits(
    update: CreditUpdate,
    user_id: str = Path(...),
    session: AsyncSession = Depends(get_session),
):
    """
    Agrega (o quita si es negativo) créditos a un usuario manualmente.
    Usa CreditUpdate para validar el body y evitar error 422 con negativos.
    """
    user = await session.get(User, user_id)
    if not user:
        raise HTTPException(404, detail="Usuario no encontrado")

    exp_date = update.expires_at
    # Convertir a naive UTC por consistencia si viene con timezone
    if exp_date and exp_date.tzinfo:
        exp_date = exp_date.astimezone(timezone.utc).replace(tzinfo=None)

    credit = Credit(
        amount=update.amount,
        user_id=UUID(user_id),
        expires_at=exp_date,
        created_at=datetime.now(),
    )
    session.add(credit)
    await session.commit()
    return {"status": "ok", "credits_added": update.amount}


# ----------- ANNOUNCEMENTS (NOVEDADES) -----------
UPLOAD_DIR = FilePath("static/uploads")
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB max antes de compresión
ALLOWED_TYPES = ["image/jpeg", "image/png", "image/webp"]
MAX_IMAGE_DIMENSION = 1200  # Max width/height after compression
JPEG_QUALITY = 85  # Compression quality

# Asegurar directorio
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)


def compress_image(
    image_bytes: bytes,
    max_dimension: int = MAX_IMAGE_DIMENSION,
    quality: int = JPEG_QUALITY,
) -> bytes:
    """
    Comprime una imagen a JPEG con dimensiones máximas y calidad reducida.
    Retorna los bytes de la imagen comprimida.
    """
    img = PILImage.open(BytesIO(image_bytes))

    # Convertir a RGB si es necesario (para PNG con alpha)
    if img.mode in ("RGBA", "P", "LA"):
        background = PILImage.new("RGB", img.size, (255, 255, 255))
        if img.mode == "P":
            img = img.convert("RGBA")
        background.paste(img, mask=img.split()[-1] if img.mode == "RGBA" else None)
        img = background
    elif img.mode != "RGB":
        img = img.convert("RGB")

    # Redimensionar si excede dimensiones máximas
    original_width, original_height = img.size
    if original_width > max_dimension or original_height > max_dimension:
        ratio = min(max_dimension / original_width, max_dimension / original_height)
        new_size = (int(original_width * ratio), int(original_height * ratio))
        img = img.resize(new_size, PILImage.Resampling.LANCZOS)

    # Guardar como JPEG comprimido
    output = BytesIO()
    img.save(output, format="JPEG", quality=quality, optimize=True)
    return output.getvalue()


@router.post("/announcements")
async def create_announcement(
    background_tasks: BackgroundTasks,
    title: Optional[str] = Form(None),
    content: Optional[str] = Form(None),
    expires_at: Optional[str] = Form(None),
    image_file: Optional[UploadFile] = File(None),
    send_push: bool = Form(False),
    current_user: User = Depends(get_current_admin),
    session: AsyncSession = Depends(get_session),
):
    """
    Crea una nueva novedad (Announcement).
    - Título y contenido opcionales.
    - Imagen opcional (se comprime automáticamente).
    - Expiración opcional.
    """

    # ---------------------------------------------------------
    # PUSH NOTIFICATION LOGIC
    # ---------------------------------------------------------
    if send_push:
        # Fetch users with valid tokens
        stmt = select(User.fcm_token).where(User.fcm_token.isnot(None))
        result = await session.execute(stmt)
        tokens = result.scalars().all()

        if tokens:
            push_title = title or "¡Nueva Novedad! 📢"
            push_body = (
                content[:150] + "..."
                if content and len(content) > 150
                else (content or "Entrá a la app para ver los detalles.")
            )

            logger.info(f"[PUSH] Queuing notification to {len(tokens)} devices.")
            background_tasks.add_task(
                send_multicast_notification,
                tokens=list(tokens),
                title=push_title,
                body=push_body,
                data={"type": "announcement"},
            )
        else:
            logger.info("[PUSH] No tokens found in DB. Skipping.")

    final_image_path = None
    has_image = image_file is not None and image_file.filename

    if has_image:
        if image_file.content_type not in ALLOWED_TYPES:
            raise HTTPException(400, detail="Solo JPG, PNG o WEBP")

        # Leer bytes del archivo
        image_bytes = await image_file.read()

        if len(image_bytes) > MAX_FILE_SIZE:
            raise HTTPException(400, detail="Máximo 5MB")

        try:
            # Comprimir imagen
            compressed_bytes = compress_image(image_bytes)

            # Siempre guardamos como .jpg después de compresión
            new_filename = f"{uuid4().hex}.jpg"
            file_path = UPLOAD_DIR / new_filename

            # Guardar bytes comprimidos
            with open(file_path, "wb") as buffer:
                buffer.write(compressed_bytes)

            final_image_path = f"/static/uploads/{new_filename}"
            logger.info(
                f"Image compressed: {len(image_bytes)} -> {len(compressed_bytes)} bytes"
            )
        except Exception as e:
            logger.error(f"Error compressing image: {e}")
            raise HTTPException(400, detail="Error procesando imagen")

    # Parse expires_at si viene como string
    parsed_expires_at = None
    if expires_at:
        try:
            parsed_expires_at = datetime.fromisoformat(
                expires_at.replace("Z", "+00:00")
            )
            # Convertir a naive UTC
            if parsed_expires_at.tzinfo:
                parsed_expires_at = parsed_expires_at.astimezone(timezone.utc).replace(
                    tzinfo=None
                )
        except (ValueError, AttributeError):
            pass  # Si no se puede parsear, dejar None

    news = Announcement(
        title=title.strip() if title else None,
        content=content.strip() if content else None,
        image_url=final_image_path,
        expires_at=parsed_expires_at,
    )
    session.add(news)
    await session.commit()
    await session.refresh(news)
    return news


@router.delete("/announcements/{news_id}")
async def delete_announcement(
    news_id: str = Path(...),
    session: AsyncSession = Depends(get_session),
):
    """Borra novedad de BD y elimina el archivo físico para no ocupar espacio."""
    try:
        news_uuid = UUID(news_id)  # <--- Ahora funciona porque importamos UUID arriba
    except ValueError:
        raise HTTPException(400, detail="ID inválido")

    news = await session.get(Announcement, news_uuid)
    if not news:
        raise HTTPException(404, detail="Novedad no encontrada")

    # 1. Borrar archivo físico si existe
    if news.image_url:
        # Quitamos la primera barra para tener path relativo local
        relative_path = news.image_url.lstrip("/")

        # Usamos libreria os estándar para borrar
        if os.path.exists(relative_path):
            try:
                os.remove(relative_path)
            except Exception as e:
                logger.warning(f"Error borrando archivo: {e}")

    # 2. Borrar de BD
    await session.delete(news)  # CRITICAL: await was missing!
    await session.commit()
    return {"status": "deleted"}


@router.patch("/users/{user_id}/toggle-trial")
async def toggle_user_trial(
    user_id: str = Path(...),
    session: AsyncSession = Depends(get_session),
):
    """Switch Modo Prueba (is_trial)."""
    user = await session.get(User, user_id)
    if not user:
        raise HTTPException(404, detail="Usuario no encontrado")

    user.is_trial = not user.is_trial
    session.add(user)
    await session.commit()
    return {"status": "updated", "is_trial": user.is_trial}
