from fastapi import (
    APIRouter,
    Depends,
    Query,
    HTTPException,
    Body,
    Path as FastPath,
    UploadFile,
    File,
    Request,
    BackgroundTasks,
)
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select, func
from sqlalchemy import or_, text
from typing import List, Optional
from datetime import datetime, timedelta
import shutil
import time
from pathlib import Path
from PIL import Image

from app.database import get_session

# Se agregan FixedSchedule y ProviderType para la lógica de merge
from app.models import (
    Instructor,
    GymClass,
    User,
    Booking,
    BookingStatus,
    Credit,
    Setting,
    Announcement,
    FixedSchedule,
    ProviderType,
)
from app.auth.dependencies import get_current_user, get_current_user_optional
from app.api.schemas import (
    GymClassRead,
    MyBookingRead,
    UserProfileReadV2,
    UserProfileUpdate,
)
from app.utils import get_setting_int, get_setting_bool
import logging

logger = logging.getLogger("uvicorn")

router = APIRouter(dependencies=[Depends(get_current_user)])


# ----------- FEEDBACK -----------
@router.post("/feedback")
async def submit_feedback(
    background_tasks: BackgroundTasks,
    sentiment: str = Body(..., embed=True),  # 'positive' | 'negative'
    message: Optional[str] = Body(None, embed=True),
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    """
    Registra el feedback del usuario.
    Si es negativo y tiene mensaje, envía email en background.
    Marca has_given_feedback = True.
    """
    # 1. Update User
    if not current_user.has_given_feedback:
        current_user.has_given_feedback = True
        current_user.feedback_sentiment = sentiment
        session.add(current_user)
        await session.commit()
        await session.refresh(current_user)

    # 2. Handle Sentiment (Email if negative)
    if sentiment == "negative" and message:
        from app.utils import send_email_background

        subject = f"Feedback Negativo de {current_user.full_name}"
        body = (
            f"Usuario: {current_user.full_name}\n"
            f"Email: {current_user.email}\n"
            f"Teléfono: {current_user.phone}\n\n"
            f"Mensaje:\n{message}"
        )

        background_tasks.add_task(
            send_email_background, subject, body, "admin@example.com"  # Email real removido para versión pública del repositorio
        )
        logger.info(
            f"[EMAIL SERVICE] Queued email for negative feedback from {current_user.email}"
        )

    return {"status": "ok"}


# ----------- PERFIL USUARIO -----------


@router.get("/me", response_model=UserProfileReadV2)
async def get_profile(
    request: Request,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    """
    Retorna el perfil del usuario autenticado.
    Calcula el saldo de créditos sumando cargas (+) y restando usos (-),
    ignorando créditos vencidos.
    """
    now = datetime.now()

    credits_result = await session.execute(
        select(Credit).where(Credit.user_id == current_user.id)
    )
    credits = credits_result.scalars().all()

    balance = 0
    for c in credits:
        # Créditos negativos (usos) siempre restan
        if c.amount < 0:
            balance += c.amount
        # Créditos positivos suman solo si no han expirado
        elif c.amount > 0 and (c.expires_at is None or c.expires_at > now):
            balance += c.amount

    # Construir URL absoluta si existe certificado
    cert_url = current_user.medical_certificate_url
    if cert_url and not cert_url.startswith("http"):
        base_url = str(request.base_url)
        # Evitar doble slash si base termina en / y path no empieza con / (o viceversa)
        # relative_path es "static/sw..."
        if base_url.endswith("/"):
            cert_url = f"{base_url}{cert_url}"
        else:
            cert_url = f"{base_url}/{cert_url}"

    return UserProfileReadV2(
        id=current_user.id,  # IMPORTANTE: Agregamos ID
        full_name=current_user.full_name,
        dni=current_user.dni,
        email=current_user.email,
        phone=current_user.phone,
        is_admin=current_user.is_admin,
        disabled=current_user.disabled,  # Agregamos disabled
        is_trial=current_user.is_trial,
        has_given_feedback=current_user.has_given_feedback,  # Agregamos feedback
        feedback_sentiment=current_user.feedback_sentiment,
        medical_certificate_url=cert_url,
        credits_available=max(balance, 0),
    )


@router.patch("/me")
async def update_profile(
    profile_data: UserProfileUpdate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    logger.debug(f"update_profile called with {profile_data}")
    full_name = profile_data.full_name
    dni = profile_data.dni
    phone = profile_data.phone
    """
    Actualiza datos del perfil.
    CRÍTICO: Implementa la lógica de 'Fusión de Cuentas' (Merge).
    Si el DNI ingresado pertenece a un 'Usuario Sombra' (creado por Admin),
    se transfieren todos sus activos al usuario actual y se elimina el Sombra.
    """
    updated = False

    if full_name is not None:
        stripped = full_name.strip()
        if not stripped:
            raise HTTPException(400, detail="Nombre no puede estar vacío")
        current_user.full_name = stripped
        updated = True

    if phone is not None:
        current_user.phone = phone.strip() if phone else None
        updated = True

    if dni is not None:
        stripped_dni = dni.strip()
        if not stripped_dni:
            raise HTTPException(400, detail="DNI no puede estar vacío")
        if not stripped_dni.isdigit():
            raise HTTPException(400, detail="DNI debe contener solo números")

        # Verificar si el DNI ya existe en OTRA cuenta
        existing_user = await session.scalar(
            select(User).where(User.dni == stripped_dni, User.id != current_user.id)
        )

        if existing_user:
            # ESTRATEGIA DE MERGE: Si es usuario LOCAL (Sombra), fusionamos.
            if existing_user.provider == ProviderType.LOCAL:
                # 1. Transferir Reservas (Con check de duplicados)
                shadow_bookings = await session.execute(
                    select(Booking).where(Booking.user_id == existing_user.id)
                )
                for b in shadow_bookings.scalars().all():
                    # Check si el usuario DESTINO ya tiene reserva en esa clase
                    duplicate_check = await session.scalar(
                        select(Booking).where(
                            Booking.gym_class_id == b.gym_class_id,
                            Booking.user_id == current_user.id
                        )
                    )
                    
                    if duplicate_check:
                        # Conflicto: Ya tiene reserva. Priorizamos conservar la que ya tiene el usuario.
                        # Borramos la reserva "sombra" duplicada para limpiar.
                        await session.delete(b)
                    else:
                        # Sin conflicto: Transferir reserva
                        b.user_id = current_user.id
                        session.add(b)

                # 2. Transferir Créditos
                shadow_credits = await session.execute(
                    select(Credit).where(Credit.user_id == existing_user.id)
                )
                for c in shadow_credits.scalars().all():
                    c.user_id = current_user.id
                    session.add(c)

                # 3. Transferir Abonos Fijos (Con check de duplicados)
                shadow_fixed = await session.execute(
                    select(FixedSchedule).where(
                        FixedSchedule.user_id == existing_user.id
                    )
                )
                for f in shadow_fixed.scalars().all():
                     # Check si el usuario DESTINO ya tiene turno fijo ese día/hora
                    duplicate_fixed = await session.scalar(
                        select(FixedSchedule).where(
                            FixedSchedule.day_of_week == f.day_of_week,
                            FixedSchedule.start_time == f.start_time,
                            FixedSchedule.user_id == current_user.id
                        )
                    )
                    
                    if duplicate_fixed:
                        # Conflicto: Ya tiene turno fijo. Priorizamos el que ya tiene.
                        await session.delete(f)
                    else:
                         f.user_id = current_user.id
                         session.add(f)

                # Transferir atributos importantes antes de borrar
                if existing_user.is_trial:
                    current_user.is_trial = True
                
                # Si el usuario nuevo no tiene apto medico y el fantasma si, lo tomamos
                if existing_user.medical_certificate_url and not current_user.medical_certificate_url:
                    current_user.medical_certificate_url = existing_user.medical_certificate_url

                # 4. Eliminar al Usuario Sombra (ya vaciado)
                # IMPORTANTE: Hacemos flush para persistir el cambio de dueño de los hijos
                # antes de borrar al padre, para evitar que SQLAlchemy intente poner sus FK en null.
                await session.flush()
                await session.refresh(existing_user)

                await session.delete(existing_user)
                await session.flush()  # FORCE DELETE to free up the DNI constraint

                # Asignar DNI al usuario real
                current_user.dni = stripped_dni
                updated = True
            else:
                # Si el conflicto es con otro usuario Real (Google/Apple), bloqueamos.
                raise HTTPException(
                    400, detail="Este DNI ya está registrado en otra cuenta activa."
                )
        else:
            # DNI libre, asignación normal
            current_user.dni = stripped_dni
            updated = True

    if not updated:
        raise HTTPException(400, detail="No se enviaron datos para actualizar")

    session.add(current_user)
    await session.commit()
    await session.refresh(current_user)
    return {"status": "updated"}


# ----------- DELETE ACCOUNT (ANDROID REQ) -----------
@router.delete("/me")
async def delete_my_account(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    """
    Eliminar cuenta del usuario (Requisito Android/iOS).
    Elimina datos de BD local (Hard Delete).
    """
    # ESTRATEGIA: Soft Delete + Anonimización
    # Esto preserva la integridad referencial de los pagos/reservas pasados
    # pero elimina toda la PII (Información Personal Identificable) del usuario.

    try:
        # 1. Anonimizar datos
        current_user.is_deleted = True  # Flag Soft Delete para filtros
        current_user.disabled = True
        current_user.full_name = "Usuario Eliminado"
        current_user.dni = None
        current_user.phone = None
        # Si social_id es NOT NULL en BD, usamos un valor dummy único
        current_user.social_id = f"deleted_{current_user.id}"
        current_user.medical_certificate_url = None

        # 2. Email único y anónimo
        timestamp = int(datetime.now().timestamp())
        current_user.email = (
            f"deleted_{current_user.id}_{timestamp}@pilatesallcanning.com"
        )

        # 3. Cancelar reservas FUTURAS
        # Esto libera los cupos para otros alumnos.
        now = datetime.now()
        future_bookings_result = await session.execute(
            select(Booking)
            .join(GymClass)
            .where(
                Booking.user_id == current_user.id,
                Booking.status == BookingStatus.CONFIRMED,
                GymClass.start_time > now,
            )
        )
        future_bookings = future_bookings_result.scalars().all()

        for booking in future_bookings:
            booking.status = BookingStatus.CANCELLED
            booking.cancelled_at = now
            session.add(booking)
            # No reembolsamos créditos porque la cuenta se está eliminando.

        session.add(current_user)
        await session.commit()
        
        logger.info(f"User {current_user.id} deleted. {len(future_bookings)} future bookings cancelled.")
        return {"status": "deleted"}

    except Exception as e:
        logger.error(f"Error deleting user: {e}")
        await session.rollback()
        raise HTTPException(500, detail="Error interno al eliminar cuenta")


import pillow_heif  # Importar para soporte HEIC

# Registrar abridor de HEIF
pillow_heif.register_heif_opener()


@router.post("/me/medical-certificate")
async def upload_medical_certificate(
    request: Request,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    """
    Sube el Apto Físico (Certificado Médico).
    - Imágenes (JPG, PNG, WEBP, HEIC): Se redimensionan a max 1200px y se comprimen a JPG (q=70).
    - PDF: Se guardan tal cual.
    - Path: static/uploads/{user_id}_medical.{ext}
    """
    ALLOWED_TYPES = [
        "image/jpeg",
        "image/png",
        "image/webp",
        "image/heic",
        "image/heif",
        "application/pdf",
    ]

    # Normalización simple de content-type para HEIC que a veces viene distinto
    if file.content_type == "application/octet-stream" and (
        file.filename.lower().endswith(".heic")
        or file.filename.lower().endswith(".heif")
    ):
        file.content_type = "image/heic"

    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            400, detail="Formato no válido (Solo JPG, PNG, WEBP, HEIC o PDF)"
        )

    UPLOAD_DIR = Path("static/uploads")
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

    try:
        if file.content_type == "application/pdf":
            filename = f"{current_user.id}_medical.pdf"
            file_path = UPLOAD_DIR / filename
            with open(file_path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)
        else:
            # Procesar Imagen con Pillow (Soporta HEIC tras register_heif_opener)
            filename = f"{current_user.id}_medical.jpg"
            file_path = UPLOAD_DIR / filename

            # Resetear puntero por si acaso
            await file.seek(0)

            img = Image.open(file.file)
            img = img.convert(
                "RGB"
            )  # Convertir todo a RGB (incluyendo RGBA de PNG/WEBP y HEIC)

            # Redimensionar (Thumbnail preserva aspect ratio)
            img.thumbnail((1200, 1200))

            # Guardar optimizado
            img.save(file_path, "JPEG", quality=70, optimize=True)

    except Exception as e:
        logger.error(f"Error procesando archivo: {e}")
        raise HTTPException(500, detail="Error interno al procesar el archivo")

    # Guardar ruta relativa en BD (accesible via http://domain/static/uploads/...)
    # Agregamos timestamp para evitar caché del navegador al actualizar
    relative_path = f"static/uploads/{filename}"
    timestamp = int(time.time())
    final_url = f"{relative_path}?t={timestamp}"

    current_user.medical_certificate_url = final_url
    session.add(current_user)
    await session.commit()

    # Construir URL absoluta para el retorno
    base_url = str(request.base_url)
    if base_url.endswith("/"):
        return_url = f"{base_url}{final_url}"
    else:
        return_url = f"{base_url}/{final_url}"

    return {"status": "ok", "url": return_url}


# ----------- INSTRUCTORS -----------





# ----------- GYM CLASSES (Grilla de Reservas) -----------


@router.get("/gym-classes", response_model=List[GymClassRead])
async def get_gym_classes(
    date_str: Optional[str] = Query(None, alias="date"),
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    """
    Retorna la grilla de clases con estado calculado para el usuario.
    - confirmed_count: Cupos ocupados.
    - my_status: Estado de la reserva del usuario actual (si existe).
    """
    # Subqueries para conteo eficiente
    confirmed_sub = (
        select(func.count(Booking.id))
        .where(
            Booking.gym_class_id == GymClass.id,
            Booking.status == BookingStatus.CONFIRMED,
        )
        .scalar_subquery()
    )
    my_status_sub = (
        select(Booking.status)
        .where(
            Booking.gym_class_id == GymClass.id,
            Booking.user_id == current_user.id,
            Booking.status != BookingStatus.CANCELLED,
        )
        .scalar_subquery()
    )

    statement = select(
        GymClass, confirmed_sub.label("confirmed"), my_status_sub.label("my_status")
    )

    # Filtro por fecha (Día específico o desde Hoy en adelante)
    if date_str:
        try:
            target_date = datetime.strptime(date_str, "%Y-%m-%d").date()
            start_of_day = datetime.combine(target_date, datetime.min.time())
            end_of_day = datetime.combine(target_date, datetime.max.time())
            statement = statement.where(
                GymClass.start_time >= start_of_day, GymClass.start_time <= end_of_day
            )
        except ValueError:
            raise HTTPException(400, detail="Formato fecha inválido: YYYY-MM-DD")
    else:
        statement = statement.where(GymClass.start_time >= datetime.now())

    # Exclude cancelled classes (Soft Delete)
    statement = statement.where(GymClass.cancelled_at.is_(None))

    statement = statement.order_by(GymClass.start_time)
    result = await session.execute(statement)

    classes = []
    for row in result:
        gym_class = row[0]
        confirmed = row.confirmed or 0
        my_status = row.my_status
        available = gym_class.max_slots - confirmed

        classes.append(
            GymClassRead(
                id=str(gym_class.id),
                name=gym_class.name,
                instructor=gym_class.instructor,
                start_time=gym_class.start_time,
                max_slots=gym_class.max_slots,
                duration_minutes=gym_class.duration_minutes,
                confirmed_count=confirmed,
                available_slots=available,
                is_full=available <= 0,
                my_status=(my_status == BookingStatus.CONFIRMED),
                recurrence_group=(
                    str(gym_class.recurrence_group)
                    if gym_class.recurrence_group
                    else None
                ),
            )
        )

    return classes


# ----------- LOGICA DE RESERVA -----------


@router.post("/gym-classes/{class_id}/book")
async def book_class(
    class_id: str = FastPath(...),
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    """
    Gestiona la reserva de una clase.
    Incluye validaciones de negocio (pausa, saldo, cupo) y seguridad (bloqueo trial).
    """

    logger.debug(
        f"book_class: User={current_user.email}, is_trial={current_user.is_trial}, is_admin={current_user.is_admin}"
    )

    # 1. Seguridad: Usuarios de prueba no pueden reservar
    if current_user.is_trial:
        raise HTTPException(
            403, detail="Tu cuenta es de prueba. Contacta a recepción para reservar."
        )

    # 2. Configuración Global: Pausa de reservas
    pause = await get_setting_bool(session, "pause_reservations", default=False)
    if pause:
        raise HTTPException(
            403, detail="Reservas pausadas temporalmente por el administrador"
        )

    gym_class = await session.get(GymClass, class_id)
    if not gym_class:
        raise HTTPException(404, detail="Clase no encontrada")
    if gym_class.start_time < datetime.now():
        raise HTTPException(400, detail="Clase pasada")

    # 3. Validación: Evitar doble reserva
    existing = await session.scalar(
        select(Booking).where(
            Booking.user_id == current_user.id, Booking.gym_class_id == class_id
        )
    )
    if existing and existing.status == BookingStatus.CONFIRMED:
        raise HTTPException(400, detail="Ya tienes reserva confirmada")

    # 4. Validación: Saldo de créditos
    now = datetime.now()
    credits = await session.execute(
        select(Credit).where(Credit.user_id == current_user.id)
    )
    balance = 0
    for c in credits.scalars().all():
        if c.amount < 0:
            balance += c.amount
        elif c.amount > 0 and (c.expires_at is None or c.expires_at > now):
            balance += c.amount

    if balance < 1:
        raise HTTPException(400, detail="No tienes créditos disponibles")

    # 5. Validación: Cupo disponible (CON LOCK PESIMISTA)
    # SELECT FOR UPDATE previene race condition cuando 2 usuarios reservan el último cupo
    await session.execute(
        text("SELECT 1 FROM gym_classes WHERE id = :id FOR UPDATE"),
        {"id": class_id},
    )
    confirmed_count = await session.scalar(
        select(func.count(Booking.id)).where(
            Booking.gym_class_id == class_id, Booking.status == BookingStatus.CONFIRMED
        )
    )
    if confirmed_count >= gym_class.max_slots:
        raise HTTPException(400, detail="Clase llena")

    # 6. Ejecución: Crear reserva (o reactivar) y descontar crédito
    if existing:  # Reactivate cancelled
        existing.status = BookingStatus.CONFIRMED
        existing.cancelled_at = None
        session.add(existing)
    else:
        booking = Booking(
            user_id=current_user.id,
            gym_class_id=class_id,
            status=BookingStatus.CONFIRMED,
        )
        session.add(booking)

    deduction = Credit(amount=-1, user_id=current_user.id)
    session.add(deduction)
    await session.commit()

    return {"status": "ok", "message": "Reserva confirmada, crédito deducido"}


# ----------- RESERVAS DEL USUARIO (Mis Clases) -----------


@router.get("/my-bookings", response_model=List[MyBookingRead])
async def get_my_bookings(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    """
    Lista el historial de reservas del usuario.
    Orden cronológico inverso (futuras primero).
    """
    now = datetime.now()

    # Subquery para calcular cupos ocupados de cada clase listada
    confirmed_sub = (
        select(Booking.gym_class_id, func.count(Booking.id).label("confirmed_count"))
        .where(Booking.status == BookingStatus.CONFIRMED)
        .group_by(Booking.gym_class_id)
        .subquery()
    )

    statement = (
        select(Booking, GymClass, confirmed_sub.c.confirmed_count)
        .join(GymClass, Booking.gym_class_id == GymClass.id)
        .outerjoin(confirmed_sub, confirmed_sub.c.gym_class_id == GymClass.id)
        .where(Booking.user_id == current_user.id)
        .order_by(GymClass.start_time.desc())
    )

    result = await session.execute(statement)

    bookings = []
    for row in result:
        booking = row[0]
        gym_class = row[1]
        confirmed_count = row[2] or 0
        available = gym_class.max_slots - confirmed_count

        # Determina si es cancelable (futura y confirmada)
        can_cancel = (
            booking.status == BookingStatus.CONFIRMED and gym_class.start_time > now
        )

        bookings.append(
            MyBookingRead(
                id=str(gym_class.id),
                name=gym_class.name,
                instructor=gym_class.instructor,
                start_time=gym_class.start_time,
                max_slots=gym_class.max_slots,
                duration_minutes=gym_class.duration_minutes,
                confirmed_count=confirmed_count,
                available_slots=available,
                is_full=available <= 0,
                my_status=(booking.status == BookingStatus.CONFIRMED),
                booking_id=str(booking.id),
                status=booking.status,
                cancelled_at=booking.cancelled_at,
                can_cancel=can_cancel,
            )
        )

    return bookings


# ----------- LOGICA CANCELAR RESERVA -----------


@router.post("/bookings/{booking_id}/cancel")
async def cancel_booking(
    booking_id: str = FastPath(...),
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    """
    Cancela una reserva existente.
    Política de reembolso:
    - Temprana (antes del tiempo límite): Se devuelve el crédito.
    - Tardía (dentro del tiempo límite): Se pierde el crédito.
    """
    # 1. Seguridad: Usuarios de prueba no pueden cancelar
    if current_user.is_trial:
        raise HTTPException(
            403, detail="Tu cuenta es de prueba. No puedes cancelar turnos."
        )

    booking = await session.get(Booking, booking_id)
    if not booking or booking.user_id != current_user.id:
        raise HTTPException(404, detail="Reserva no encontrada")

    if booking.status != BookingStatus.CONFIRMED:
        raise HTTPException(400, detail="Solo se pueden cancelar reservas confirmadas")

    gym_class = await session.get(GymClass, booking.gym_class_id)
    now = datetime.now()
    if gym_class.start_time <= now:
        raise HTTPException(400, detail="No se puede cancelar clase pasada o en curso")

    # 2. Cálculo de penalización
    cancel_minutes = await get_setting_int(session, "cancel_minutes_before", default=10)
    limit_time = gym_class.start_time - timedelta(minutes=cancel_minutes)

    logger.debug(
        f"cancel_booking: id={booking_id}, class_start={gym_class.start_time}, now={now}, limit={limit_time}, cancel_min={cancel_minutes}"
    )

    refund_given = False
    if now < limit_time:
        refund = Credit(amount=1, user_id=current_user.id)
        session.add(refund)
        refund_given = True
        message = "Reserva cancelada. Crédito reembolsado."
        logger.info(f"cancel_booking: REFUND GIVEN for {booking_id}")
    else:
        message = "Cancelación tardía. No se ha reembolsado el crédito."
        logger.info(f"cancel_booking: NO REFUND for {booking_id} (late)")

    booking.status = BookingStatus.CANCELLED
    booking.cancelled_at = now
    session.add(booking)
    await session.commit()

    return {
        "status": "ok",
        "message": message,
        "refunded": refund_given,
    }


# ----------- ANNOUNCEMENTS -----------


@router.get("/announcements", response_model=List[Announcement])
async def get_announcements(
    request: Request,
    include_expired: bool = Query(False),
    session: AsyncSession = Depends(get_session),
    current_user: Optional[User] = Depends(get_current_user_optional),
):
    """
    Retorna el feed de novedades (Announcements).
    - Para usuarios normales: solo vigentes (sin expirar)
    - Para admins con include_expired=true: todas (incluye expiradas)
    Ordenadas por fecha de creación descendente.
    """
    query = select(Announcement)

    # Solo mostrar TODAS si se pide include_expired=true Y el usuario es admin
    # Caso contrario, filtrar por vigentes
    is_admin = current_user is not None and current_user.is_admin
    show_all = include_expired and is_admin

    if not show_all:
        now = datetime.now()
        query = query.where(
            or_(Announcement.expires_at.is_(None), Announcement.expires_at > now)
        )

    query = query.order_by(Announcement.created_at.desc())
    result = await session.execute(query)
    announcements = result.scalars().all()

    # Construir URL absoluta para imágenes
    base_url = str(request.base_url).rstrip("/")
    for a in announcements:
        if a.image_url and not a.image_url.startswith("http"):
            # Si empieza con /, quitamos para evitar doble //
            rel_path = a.image_url.lstrip("/")
            a.image_url = f"{base_url}/{rel_path}"

    return announcements
