# QuickSlot: Frontend & Backend Architecture

QuickSlot is a modern mobile-first booking application designed for reserving sports slots (e.g., badminton courts, football turfs, tennis, and basketball courts). 

This repository is organized as a monorepo containing:
1. **Frontend App (`quickslot_mobile_app/`)**: A Flutter application using Riverpod for state management.
2. **Backend Service (`quickslot_backend/`)**: A Node.js Express REST API connected to a PostgreSQL database.

---

## System Architecture Overview

The system follows a classic client-server architecture. The Flutter mobile application communicates with the Express backend using HTTP REST endpoints, secured with custom header-based identity propagation.

```mermaid
graph TD
    %% Frontend Layer
    subgraph Frontend [Flutter Mobile App]
        UI[Presentation Layer: Screens & Widgets]
        VM[Application Layer: Riverpod Notifiers]
        Repo[Data Layer: Repositories]
        DioClient[Network Layer: Dio HTTP Client]
        Cache[(Local Storage: SharedPreferences)]
    end

    %% Backend Layer
    subgraph Backend [Node.js Express API]
        Router[Router Layer]
        Controller[Controller Layer: Request Validation]
        Service[Service Layer: Business Logic]
        Middleware[Middlewares: Auth & Error Handling]
    end

    %% Database Layer
    subgraph Database [PostgreSQL Database]
        DB[(PostgreSQL Tables: Venues & Bookings)]
    end

    %% Data Flows
    UI -->|Reads State / Triggers Actions| VM
    VM -->|Calls Functions| Repo
    Repo -->|Performs API Requests| DioClient
    Repo -->|Reads/Writes Offline Cache| Cache
    DioClient <-->|HTTP REST with X-User-Id| Router
    Router -->|Passes through| Middleware
    Middleware -->|Injects req.userId| Controller
    Controller -->|Calls Services| Service
    Service <-->|Queries SQL Pool| DB
```

---

## 📱 Frontend Architecture (`quickslot_mobile_app`)

The frontend is a cross-platform mobile application written in **Dart** using **Flutter**. It is designed with a **Feature-First Layered Architecture** to ensure clean separation of concerns and maintainability.

### Key Technology Stack
*   **State Management & DI**: [Riverpod (v2.x)](https://riverpod.dev/) utilizing `AsyncNotifier`, `Notifier`, and family-based auto-dispose providers.
*   **Routing**: [GoRouter](https://pub.dev/packages/go_router) featuring declarative route configuration and auth-state-driven redirection guards.
*   **Networking**: [Dio](https://pub.dev/packages/dio) HTTP client with custom interceptors for request/response logging and automated header enrichment.
*   **Local Caching**: [SharedPreferences](https://pub.dev/packages/shared_preferences) for caching booking listings offline.

### Directory Structure
The frontend files are organized under `lib/` by feature, with a shared `core` and `app` setup:

```
lib/
├── app/
│   ├── app.dart              # Root MaterialApp widget configuration
│   └── router.dart           # GoRouter declarations & auth redirection guards
├── core/
│   ├── network/
│   │   └── api_client.dart   # Dio HTTP Provider with X-User-Id request interceptor
│   └── theme/                # Global style tokens, custom colors, and typography
└── features/
    ├── auth/                 # Simulated identity management & user sessions
    ├── bookings/             # Booking slots list, cancellation flow, and caching
    └── venues/               # Venue search listings, details, and dynamic slots list
```

### Clean Architecture Layers (Per Feature)
Each feature folder is split into four distinct layers:
1.  **Domain Layer**: Pure Dart models representing entities (e.g. `Venue`, `VenueSlot`, `Booking`).
2.  **Data Layer**: Contains API repositories, implementation details (`*RepositoryImpl`), and data caches. The repository intercepts network requests to fall back to cached data from `SharedPreferences` when offline.
3.  **Application Layer**: Contains State Notifiers (e.g. `VenuesNotifier`, `VenueSlotsNotifier`) managing asynchronous state transitions (`AsyncValue` states: data, loading, error).
4.  **Presentation Layer**: Screens, forms, and custom widgets (e.g. `VenueDetailScreen`, `MyBookingsScreen`).

---

## ⚙️ Backend Architecture (`quickslot_backend`)

The backend is a lightweight REST API written in **Node.js** using the **Express** framework. It uses a **Layer-First Architecture** to handle routing, request validation, business logic, and database operations.

### Key Technology Stack
*   **Framework**: [Express](https://expressjs.com/) for routing and middleware pipeline.
*   **Database Client**: `pg` (node-postgres) utilizing connection pooling (`Pool`) to manage connections efficiently.
*   **Authentication**: Stateless header-based auth verifying client requests via the `X-User-Id` header.
*   **Security & CORS**: [cors](https://pub.dev/packages/cors) middleware configured to handle cross-origin requests.

### Directory Structure
```
src/
├── config/
│   └── db.js                 # PG Pool configuration, schema creation, & seeding
├── controllers/              # Request validation and JSON response mapping
├── middlewares/              # Express middlewares (Auth check & global error handler)
├── routes/                   # Endpoint routers (Venue routes, Booking routes)
├── services/                 # Business logic and database operations
├── utils/                    # Common helpers (Date/time formatters)
├── app.js                    # Express application lifecycle configurations
└── server.js                 # Entry point, initializes DB and spins up listener
```

---

## 🗄️ Database Schema & Concurrency

The database is built on **PostgreSQL**. The schema contains two tables with strict constraints to ensure booking consistency.

```sql
CREATE TABLE IF NOT EXISTS venues (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  sport VARCHAR(100) NOT NULL,
  location VARCHAR(255) NOT NULL,
  image_url TEXT
);

CREATE TABLE IF NOT EXISTS bookings (
  id SERIAL PRIMARY KEY,
  venue_id VARCHAR(50) NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  booking_date DATE NOT NULL,
  start_time TIME NOT NULL,
  user_id VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT unique_venue_slot UNIQUE (venue_id, booking_date, start_time)
);
```

### Concurrency Handling
Double bookings are prevented at the database layer using a unique composite index (`unique_venue_slot` on `(venue_id, booking_date, start_time)`). 
If two users concurrently attempt to book the exact same slot for a venue, the PostgreSQL engine rejects the second transaction with a unique constraint violation, which is handled gracefully by the backend and returned as a standard error response.

---

## 🔌 API Contract (REST Endpoints)

All endpoints return JSON and accept JSON payloads. 

### 1. Venues
*   **`GET /venues`**
    *   **Description**: Get all sports venues sorted alphabetically by ID.
    *   **Response**: `200 OK` with an array of venues.
*   **`GET /venues/:id/slots?date=YYYY-MM-DD`**
    *   **Description**: Get all hourly slots (from `06:00` to `22:00`) for a specific date.
    *   **Response**: `200 OK` with slots showing statuses (`available` vs `booked`) and client identities.

### 2. Bookings
*   **`POST /bookings`**
    *   **Description**: Book a slot at a venue.
    *   **Headers**: `X-User-Id: <user_id>` (Required)
    *   **Payload**:
        ```json
        {
          "venue_id": "smash-arena",
          "date": "2026-06-11",
          "start_time": "14:00"
        }
        ```
    *   **Response**: `201 Created` on success, `400 Bad Request` if in the past, or database error if already booked.
*   **`GET /users/:id/bookings`**
    *   **Description**: Fetch all active bookings for a specific user.
    *   **Response**: `200 OK` with an array of bookings with venue location and sport info.
*   **`DELETE /bookings/:id`**
    *   **Description**: Cancel an existing slot reservation.
    *   **Headers**: `X-User-Id: <user_id>` (Must match booking owner)
    *   **Response**: `200 OK` on success, `403 Forbidden` if cancelled by another user, or `404 Not Found`.

---

## 🚀 Getting Started

### 1. Run the Backend
1. Navigate into the backend directory:
   ```bash
   cd quickslot_backend
   ```
2. Install Node dependencies:
   ```bash
   npm install
   ```
3. Create a `.env` file or export your database credentials:
   ```env
   DATABASE_URL=postgresql://user:password@host:port/database
   PORT=3000
   ```
   *(Note: If no `DATABASE_URL` is provided, it falls back to connection configuration using `DB_HOST`, `DB_PORT`, `DB_DATABASE`, etc., pointing to localhost)*
4. Run the Express server:
   ```bash
   npm start
   ```
   The backend automatically connects to Postgres, validates or creates the tables, inserts seed venues, and starts listening on port `3000`.

### 2. Run the Mobile App
1. Navigate into the mobile app directory:
   ```bash
   cd quickslot_mobile_app
   ```
2. Fetch Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. (Optional) Check code analysis:
   ```bash
   flutter analyze
   ```
4. Run on your preferred target device (iOS, Android, Chrome):
   ```bash
   flutter run
   ```
   *(Note: The base URL points to the production server by default. To connect to your local backend, edit `lib/core/network/api_client.dart` and change the `baseUrl` to your local environment IP).*
