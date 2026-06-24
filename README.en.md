[English](README.en.md) | [Español](README.md)

# PilatesAllCanning — Booking Management App for a Pilates Franchise

A complete management system built with **Flutter + Python (FastAPI) + PostgreSQL + Firebase** for a pilates gym franchise in Argentina. It includes a multiplatform app (iOS, Android, Web) for students and an administration panel.

A complete freelance project: from client acquisition to final delivery. I worked as the sole developer, defining requirements directly with the client, proposing features and making product decisions. The goal: a functional, easy-to-use app that allows delegating and organizing the management of the franchise.

---

## 🛠️ Tech Stack

| Layer | Technology |
|------|------------|
| **Frontend** | Flutter 3.x, Riverpod, Freezed, GoRouter, Dio |
| **Backend** | Python, FastAPI (async), SQLModel, asyncpg |
| **Database** | PostgreSQL 16, Alembic |
| **Auth** | Firebase Authentication (Google, Apple) |
| **Storage** | Firebase Storage |
| **Notifications** | Firebase Cloud Messaging |
| **Infra** | Docker Compose, Nginx, Hetzner VPS|

---

## 📸 MVP Demo (Click the image to watch on YouTube)

[![Demo MVP — PilatesAllCanning](https://img.youtube.com/vi/EVlTbLLV_NU/hqdefault.jpg)](https://youtu.be/EVlTbLLV_NU?si=2hsUCER-hNNN0GqR)

---

**Some of the features and business problems it solves:**

**Bookings and classes**
- Browse available classes with information on slots, schedules and instructor
- Booking of specific slots with validation of slots, credits and schedules —avoiding overbooking
- Fixed slots (memberships) with automatic weekly auto-booking
- Recurring classes: the administrator creates a class once and the system automatically generates the weekly instances, respecting Argentine holidays
- Cancellation with a penalty policy for late cancellation or no-show
- Manual booking by the administrator, including creating users without the app (Shadow Users)

**User management**
- Student categories: regular student, student without app (Shadow User created by the administrator), trial student (attends a trial class, with no membership or commitment — not allowed to book or cancel classes)
- Complete class history (attended, cancelled, upcoming) visible to administrators per student and to each student for their own data
- Blocking/unblocking users with automatic cancellation of future bookings
- Account deletion by the user (Google Play / App Store requirement)
- Automatic account merge: the administrator can create a Shadow User (name + DNI) for students who do not yet have the app, keeping the real projection of slots and statistics. When that student registers and enters their DNI, the app detects the match and automatically merges both accounts, preserving fixed slots, credits and all previous history
- Instructor management (full CRUD)

**Credits and payments**
- Credit system with expiration and automatic deduction per booking

**Communication**
- News section with push notifications (Firebase Cloud Messaging), image support with automatic compression
- Automated post-interaction feedback with an email alert to the administrator on negative responses
- Section with useful information for the user

**Documentation**
- Upload of medical clearance (PDF or image) with automatic compression

**Administration**
- Complete administrator panel with feedback status per user (positive/negative/no response)
- Monthly calendar view with the history of classes taught and their occupancy level (current and previous month)
- Monthly raffle among active students, weighted by attendance (more confirmed bookings in the month = more chances), to encourage consistency
- Global configuration (pause bookings, adjust parameters)
- Dynamic holiday management from the app: adding and removing non-working days without the need for a deploy, reflected in the calendar and respected in the auto-booking of recurring classes
- Design that prevents students from breaking the order of the business, and an intuitive administrator panel to avoid management errors

**Security and access**
- Master password at onboarding: without a code previously provided by the administrator, registration is not possible — preventing users from outside the gym
- Email change by the administrator: if a student loses access to their email, the administrator can update it without them losing their account or their history

**Infrastructure**
- Multiplatform Flutter app (iOS, Android, Web) from a single codebase
- Async backend with Docker Compose, Nginx and PostgreSQL
- Deploy on a VPS optimized for low operating cost

> ⚠️ **Trimmed public version**: This repository is a safe selection of the code for a portfolio. The original project is more extensive and is sanitized for client privacy. For access to the complete repository (100% functional), get in touch privately.



## 📁 Project Structure (Full Original)

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
│       │   │       ├── admin_calendar_screen.dart
│       │   │       ├── admin_users_screen.dart
│       │   │       ├── admin_settings_screen.dart
│       │   │       ├── admin_announcements_screen.dart
│       │   │       ├── admin_raffle_screen.dart
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

---


## 📝 Development Notes

**Methodology:** Development assisted by LLMs to maximize execution speed, error analysis, documentation generation, frontend design, widgets and syntax. The architecture, business logic, concurrency validations and product decisions were defined by me.

**Result:** A functional MVP delivered to a real client, running in production with minimal operating cost (~$4/month).

---

## 📬 Contact

**Iván Gómez Dell'Osa**

- LinkedIn: [ivangomezdellosa](https://www.linkedin.com/in/ivangomezdellosa/)
- Email: [ivangomezdellosa@gmail.com](mailto:ivangomezdellosa@gmail.com)
- GitHub: [IvanGomezDellOsa](https://github.com/IvanGomezDellOsa)

---
