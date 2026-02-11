# PilatesAllCanning — App de Gestión de Reservas para Franquicia de Pilates

Sistema de gestión completo desarrollado con **Flutter + Python (FastAPI) + PostgreSQL + Firebase** para una franquicia de gimnasios de pilates en Argentina. Incluye app multiplataforma (iOS, Android, Web) para alumnos y panel de administración.

Proyecto freelance completo: desde la captación del cliente hasta la entrega final. Trabajé como único developer, definiendo requisitos directamente con el cliente, proponiendo funcionalidades y tomando decisiones de producto. El objetivo: una app funcional, fácil de usar, que permita delegar y organizar la gestión de la franquicia.

---

## 🛠️ Stack Tecnológico

| Capa | Tecnología |
|------|------------|
| **Frontend** | Flutter 3.x, Riverpod, Freezed, GoRouter, Dio |
| **Backend** | Python, FastAPI (async), SQLModel, asyncpg |
| **Base de datos** | PostgreSQL 16, Alembic |
| **Auth** | Firebase Authentication (Google, Apple) |
| **Storage** | Firebase Storage |
| **Notifications** | Firebase Cloud Messaging |
| **Infra** | Docker Compose, Nginx, Hetzner VPS|

---

**Algunas de las funcionalidades y problemas de negocio que resuelve:**

**Reservas y clases**
- Consulta de clases disponibles con información de cupos, horarios e instructor
- Reservas de turnos específicos con validación de cupos, créditos y horarios —evitando overbooking
- Turnos fijos (abonos) con auto-booking semanal automático
- Clases recurrentes: el administrador crea una clase una vez y el sistema genera automáticamente las instancias semanales, respetando feriados argentinos
- Cancelación con política de sanciones por tardía o ausencia
- Reserva manual por administrador, incluyendo creación de usuarios sin app (Shadow Users)

**Gestión de usuarios**
- Categorías de alumno: alumno regular, alumno sin app (Shadow User creado por administrador), alumno de prueba (asiste a una clase de prueba, sin abono ni compromiso — no tiene habilitado reservar ni cancelar clases)
- Historial completo de clases (asistidas, canceladas, próximas) visible para administradores por alumno y para cada alumno sobre sus propios datos
- Bloqueo/desbloqueo de usuarios con cancelación automática de reservas futuras
- Eliminación de cuenta por el usuario (requisito Google Play / App Store)
- Merge automático de cuentas: el administrador puede crear un Shadow User (nombre + DNI) para alumnos que aún no tienen la app, manteniendo la proyección real de cupos y estadísticas. Cuando ese alumno se registra e ingresa su DNI, la app detecta la coincidencia y fusiona automáticamente ambas cuentas, preservando turnos fijos, créditos y todo el historial previo
- Gestión de instructores (CRUD completo)

**Créditos y pagos**
- Sistema de créditos con vencimiento y descuento automático por reserva

**Comunicación**
- Sección de novedades con notificaciones push (Firebase Cloud Messaging), soporte de imagen con compresión automática
- Feedback automatizado post-interacción con alerta por email al administrador ante respuestas negativas
- Sección de información útil para el usuario

**Documentación**
- Carga de apto médico (PDF o imagen) con compresión automática

**Administración**
- Panel de administrador completo con estado de feedback por usuario (positivo/negativo/sin respuesta)
- Configuración global (pausar reservas, ajustar parámetros)
- Diseño que impide que los alumnos rompan el orden del negocio, y panel de administrador intuitivo para evitar errores de gestión

**Seguridad y acceso**
- Contraseña maestra en el onboarding: sin un código proporcionado previamente por el administrador, no es posible registrarse — evita usuarios ajenos al gimnasio
- Cambio de email por administrador: si un alumno pierde acceso a su correo, el administrador puede actualizarlo sin que pierda su cuenta ni su historial

**Infraestructura**
- App multiplataforma Flutter (iOS, Android, Web) desde un mismo codebase
- Backend async con Docker Compose, Nginx y PostgreSQL
- Deploy en VPS optimizado para bajo costo operativo

> ⚠️ **Versión pública recortada**: Este repositorio es una selección segura del código para portfolio. El proyecto original es más extenso y está sanitizado por privacidad del cliente. Para acceso al repositorio completo (100% funcional), escribir por privado.



## 📁 Estructura del Proyecto (Original Completo)

```
PilatesAllCanning/
├── backend/
│   ├── app/
│   │   ├── api/
│   │   │   ├── adminEP.py        # Endpoints administración
│   │   │   ├── clientEP.py       # Endpoints cliente
│   │   │   ├── authEP.py         # Autenticación Firebase
│   │   │   ├── publicEP.py       # Endpoints públicos
│   │   │   └── schemas.py        # Validaciones Pydantic
│   │   ├── auth/
│   │   │   ├── firebase.py       # Firebase Admin SDK
│   │   │   └── dependencies.py   # Inyección de dependencias
│   │   ├── models.py             # SQLModel entities
│   │   ├── database.py           # Conexión async PostgreSQL
│   │   ├── notifications.py      # FCM push notifications
│   │   └── utils.py              # Helpers
│   ├── alembic/                  # Migraciones DB
│   ├── nginx/                    # Configuración reverse proxy
│   ├── scripts/                  # Deploy, backup, utilidades
│   ├── Dockerfile
│   ├── docker-compose.yml        # Desarrollo local
│   └── docker-compose.prod.yml   # Producción
│
├── frontend/
│   └── lib/
│       ├── core/
│       │   ├── providers/        # Riverpod providers globales
│       │   ├── repositories/     # Capa de datos
│       │   ├── router/           # GoRouter config
│       │   ├── services/         # API client (Dio)
│       │   └── theme/            # Design system
│       ├── features/
│       │   ├── admin/
│       │   │   └── presentation/
│       │   │       ├── admin_home_screen.dart
│       │   │       ├── admin_users_screen.dart
│       │   │       ├── admin_settings_screen.dart
│       │   │       ├── admin_announcements_screen.dart
│       │   │       └── admin_user_bookings_screen.dart
│       │   ├── auth/
│       │   │   └── presentation/  # Login, registro
│       │   └── client/
│       │       └── presentation/
│       │           ├── client_home_screen.dart
│       │           ├── client_profile_screen.dart
│       │           ├── client_my_classes_screen.dart
│       │           ├── client_announcements_screen.dart
│       │           └── widgets/
│       │               └── feedback_dialog.dart
│       ├── models/               # Freezed models (19 archivos)
│       └── main.dart
│
└── docs/
    └── screenshots/
```

---

## 📸 Screenshots / Demo


---


## 📝 Notas de Desarrollo

**Metodología:** Desarrollo asistido por LLMs para maximizar velocidad de ejecución, análisis de errores, generación de documentación, diseño frontend, widgets y sintaxis. La arquitectura, lógica de negocio, validaciones de concurrencia y decisiones de producto fueron definidas por mí.

**Resultado:** MVP funcional entregado a cliente real, corriendo en producción con costo operativo mínimo (~$4/mes).

---

## 📬 Contacto

**Iván Gómez Dell'Osa**

- LinkedIn: [ivangomezdellosa](https://www.linkedin.com/in/ivangomezdellosa/)
- Email: [ivangomezdellosa@gmail.com](mailto:ivangomezdellosa@gmail.com)
- GitHub: [IvanGomezDellOsa](https://github.com/IvanGomezDellOsa)

---