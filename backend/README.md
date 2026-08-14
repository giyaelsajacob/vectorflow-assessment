# VectorFlow

VectorFlow is a production-oriented cross-platform task package processing system built with Flutter and NestJS.

The project demonstrates offline-first mobile behavior, asynchronous background processing, real-time status updates, external provider normalization, secure authentication and authorization, idempotency, payment workflows, concurrency protection, and audit logging.

---

## Technology Stack

### Mobile

- Flutter
- Dart
- Offline operation queue
- Socket.IO realtime communication

### Backend

- NestJS
- TypeScript
- Prisma ORM
- PostgreSQL
- Redis
- BullMQ
- Socket.IO
- JWT authentication

### Infrastructure

- Docker
- PostgreSQL 16
- Redis 7

---

# Core Features

## Authentication & Security

The backend implements:

- User registration and login
- JWT access-token authentication
- Refresh-token support
- Role-based access control
- USER / REVIEWER / ADMIN roles
- Resource ownership validation
- IDOR protection
- Helmet security headers
- DTO validation
- Request payload whitelisting
- Rejection of unexpected DTO properties
- Global API rate limiting

---

## Task Packages

Users can create task packages containing:

- Items
- Priority
- Notes
- Location
- Attachments

A package progresses through the following lifecycle:

```text
submitted
    ↓
processing
    ↓
waiting_for_external_result
    ↓
ready
    ↓
completed
```

Processing failures transition the package to:

```text
failed
```

Package status changes are persisted in `PackageStatusHistory`.

---

## Asynchronous Processing

Package processing is handled asynchronously using:

- Redis
- BullMQ
- NestJS background workers

The API creates the package and queues the processing operation instead of blocking the HTTP request while external processing completes.

BullMQ jobs use deterministic package-based identifiers to reduce duplicate queue submissions.

Database-level protections and idempotent writes provide additional protection when operations are retried.

---

## External Provider Integration

VectorFlow integrates three mock external providers with intentionally different response contracts.

### Provider A

Provider A demonstrates a nested JSON response.

Its provider-specific response is transformed into the application's normalized provider result format.

### Provider B

Provider B demonstrates external-service failure recovery.

The first attempt intentionally fails with a simulated timeout.

The subsequent retry succeeds.

This demonstrates predictable timeout/retry handling rather than only documenting retry behavior.

### Provider C

Provider C demonstrates:

- Multiple provider results
- Duplicate external results
- Deduplication before persistence

Only unique normalized results are stored.

### Normalized Provider Result

Provider-specific contracts are converted into a common representation containing fields such as:

```text
provider
externalId
status
score
message
```

This prevents the Flutter application from needing to understand individual provider response formats.

---

## Realtime Updates

Socket.IO is used to send package status changes from the NestJS backend to the Flutter application.

Example realtime lifecycle:

```text
processing
→ waiting_for_external_result
→ ready
→ completed
```

The mobile application updates its local package state when these events are received.

---

## Offline-First Mobile Behavior

The Flutter application supports operations during unstable or unavailable connectivity.

Operations that cannot immediately reach the backend can be queued locally and synchronized when connectivity becomes available again.

The synchronization design uses idempotency mechanisms to reduce duplicate business operations caused by retries.

Examples include:

- Package creation using a unique `clientId`
- Attachment uploads using an `Idempotency-Key`

---

## Attachments

Task packages support file attachments.

The backend performs:

- Package existence validation
- Ownership validation
- Attachment metadata persistence
- Idempotent upload handling
- Duplicate temporary-file cleanup

A user cannot upload an attachment to a package owned by another user.

---

# Payments

VectorFlow includes a mock payment workflow to demonstrate production payment concepts without handling real payment credentials.

Supported operations include:

- Payment intent creation
- Payment confirmation
- Payment failure simulation
- Webhook processing
- Duplicate webhook protection
- Refund processing

No real card information or production payment provider is used.

---

## Payment Idempotency

Payment intent creation requires an:

```text
Idempotency-Key
```

Repeated requests using the same key return the existing payment instead of creating another payment.

This protects against duplicate charges caused by network retries or repeated client requests.

---

## Payment Lifecycle

Example successful payment lifecycle:

```text
REQUIRES_CONFIRMATION
        ↓
PROCESSING
        ↓
SUCCEEDED
```

A failed provider operation results in:

```text
FAILED
```

A fully refunded successful payment becomes:

```text
REFUNDED
```

---

## Webhook Deduplication

Payment webhook events contain a unique provider event ID.

The database prevents the same provider event from producing duplicate business effects.

The first webhook is processed normally.

A repeated webhook with the same provider event ID is recognized as a duplicate and does not repeat the payment operation.

---

# Concurrency & Idempotency

The system contains multiple layers of duplicate-operation protection.

### Package Creation

`TaskPackage.clientId` is unique.

If the same client operation is retried, the existing package can be returned instead of creating another package.

Ownership is checked before returning an existing package.

### Queue Processing

BullMQ processing uses deterministic package-based job IDs.

This helps prevent duplicate queue entries for the same package.

### Provider Results

Provider results use a composite uniqueness constraint:

```text
packageId + provider + externalId
```

Results are written using Prisma `upsert`.

This prevents repeated processing from creating duplicate provider results.

### Attachment Uploads

Attachment idempotency keys prevent duplicate attachment records when an offline upload is retried.

### Payments

Payment intent idempotency prevents duplicate payment creation.

### Webhooks

Unique provider event IDs prevent duplicate webhook business effects.

---

# Authorization / IDOR Protection

Resource identifiers alone are never treated as sufficient authorization.

For example, when retrieving a package, the backend validates both:

```text
packageId
+
authenticated userId
```

A user therefore cannot retrieve another user's package simply by discovering or guessing its UUID.

Similar ownership checks are applied to attachments and payments.

---

# Audit Trail

Important business operations can be recorded in the `AuditLog` table.

Audit records can contain:

- Actor ID
- Action
- Entity
- Entity ID
- Previous value
- New value
- Context
- Timestamp

Example action:

```text
PACKAGE_CREATED
```

The audit trail provides traceability for important application operations.

Sensitive authentication credentials and tokens should never be stored in audit records.

---

# Database

PostgreSQL is used as the primary relational database.

Prisma provides database access and migration management.

Main entities include:

- User
- RefreshToken
- TaskPackage
- PackageItem
- Attachment
- PackageStatusHistory
- ProviderResult
- Payment
- PaymentWebhookEvent
- AuditLog

Database migrations are stored in:

```text
prisma/migrations
```

---

# Architecture

```mermaid
flowchart TD
    A[Flutter Mobile Application]

    A -->|REST API / JWT| B[NestJS Backend]
    A <-->|Socket.IO| M[Realtime Gateway]

    B --> C[Authentication and RBAC]
    B --> D[Packages Module]
    B --> E[Payments Module]
    B --> F[Audit Service]

    D --> G[(PostgreSQL / Prisma)]
    E --> G
    F --> G

    D --> H[(Redis)]
    H --> I[BullMQ Background Worker]

    I --> J[Provider A]
    I --> K[Provider B - Timeout and Retry]
    I --> L[Provider C - Deduplication]

    I --> G

    M --> A

    A --> N[Offline Operation Queue]
    N -->|Reconnect and Synchronize| B

    E --> O[Mock Payment Provider]
```

---

# Database Design

```mermaid
erDiagram

    User ||--o{ RefreshToken : has
    User ||--o{ TaskPackage : owns

    TaskPackage ||--o{ PackageItem : contains
    TaskPackage ||--o{ Attachment : has
    TaskPackage ||--o{ PackageStatusHistory : tracks
    TaskPackage ||--o{ ProviderResult : receives
    TaskPackage ||--o{ Payment : has

    Payment ||--o{ PaymentWebhookEvent : receives

    User {
        string id PK
        string name
        string email UK
        string passwordHash
        Role role
        datetime createdAt
        datetime updatedAt
    }

    RefreshToken {
        string id PK
        string tokenHash
        string userId FK
        datetime expiresAt
        datetime createdAt
    }

    TaskPackage {
        string id PK
        string clientId UK
        string userId FK
        PackagePriority priority
        string notes
        float latitude
        float longitude
        PackageStatus status
        datetime createdAt
        datetime updatedAt
    }

    PackageItem {
        string id PK
        string packageId FK
        string name
        string description
        int quantity
    }

    Attachment {
        string id PK
        string packageId FK
        string fileName
        string url
        string mimeType
        int size
        string idempotencyKey UK
        datetime createdAt
    }

    PackageStatusHistory {
        string id PK
        string packageId FK
        PackageStatus status
        datetime createdAt
    }

    ProviderResult {
        string id PK
        string packageId FK
        string provider
        string externalId
        string status
        float score
        string message
        string rawHash
        datetime createdAt
    }

    Payment {
        string id PK
        string packageId FK
        string userId FK
        string idempotencyKey UK
        string providerPaymentId UK
        int amountMinor
        string currency
        string status
        string failureReason
        int refundedAmount
        datetime createdAt
        datetime updatedAt
    }

    PaymentWebhookEvent {
        string id PK
        string paymentId FK
        string providerEventId UK
        string eventType
        string status
        datetime processedAt
    }

    AuditLog {
        string id PK
        string actorId
        AuditAction action
        string entity
        string entityId
        json oldValue
        json newValue
        string context
        datetime createdAt
    }
```

---

# Local Development Setup

## Requirements

Install:

- Node.js
- npm
- Docker Desktop
- Flutter SDK

Verify Docker is running before starting the infrastructure.

---

## Environment Configuration

Copy:

```text
.env.example
```

to:

```text
.env
```

Configure the required environment variables.

Example:

```env
DATABASE_URL="postgresql://vectorflow:vectorflow@localhost:5432/vectorflow?schema=public"

JWT_SECRET="replace-with-a-long-secure-secret"
JWT_REFRESH_SECRET="replace-with-another-long-secure-secret"

REDIS_HOST="localhost"
REDIS_PORT="6379"

PORT="3000"
```

Production credentials must never be committed to source control.

---

# Backend Setup

Install dependencies:

```bash
npm install
```

Start PostgreSQL and Redis:

```bash
docker compose up -d
```

Verify containers:

```bash
docker ps
```

Generate Prisma Client:

```bash
npx prisma generate
```

Apply database migrations:

```bash
npx prisma migrate deploy
```

Verify migration status:

```bash
npx prisma migrate status
```

Start the NestJS development server:

```bash
npm run start:dev
```

The API is available at:

```text
http://localhost:3000/api
```

Build the backend:

```bash
npm run build
```

---

# Flutter Setup

Open the Flutter project separately.

Install Flutter dependencies:

```bash
flutter pub get
```

Verify the Flutter environment:

```bash
flutter doctor
```

Run the application:

```bash
flutter run
```

When testing with a physical Android device, configure the backend base URL to use the development computer's reachable local-network IP address rather than `localhost`.

---

# Verification

Automated verification scripts are included for Windows and Unix-like environments.

## Windows

Run:

```powershell
powershell -ExecutionPolicy Bypass -File ./verify.ps1
```

The Windows verification checks:

- Docker containers
- PostgreSQL readiness
- Prisma migration status
- Prisma schema validity
- Prisma Client generation
- Backend compilation
- Unauthorized API access
- Dependency security audit

## Linux / macOS

Run:

```bash
chmod +x verify.sh
./verify.sh
```

---

## Windows Prisma Note

When the NestJS application is running, Windows can lock Prisma's query-engine DLL.

In that situation:

```bash
npx prisma generate
```

may report an `EPERM` rename error.

Stop the running NestJS/Node process and run Prisma generation again.

This does not indicate a database migration failure.

---

# Security

VectorFlow currently demonstrates the following security controls:

- JWT authentication
- Refresh-token handling
- Role-based authorization
- Resource ownership validation
- IDOR protection
- DTO validation
- Input whitelisting
- Helmet HTTP security headers
- API rate limiting
- Package idempotency
- Attachment idempotency
- Payment idempotency
- Webhook deduplication
- Audit logging

---

## Dependency Security

The current development dependency audit reports:

```text
28 vulnerabilities
3 low
16 moderate
8 high
1 critical
```

Some automatic remediations require breaking upgrades to NestJS platform/CLI packages and bcrypt.

`npm audit fix --force` was intentionally not applied to the verified submission build because it can introduce breaking dependency changes.

Before a production release, dependencies should be upgraded through a controlled upgrade cycle followed by regression and security testing.

---

# Verification Evidence

The implementation has been manually verified for the following scenarios:

### Package Processing

Observed lifecycle:

```text
processing
→ waiting_for_external_result
→ ready
→ completed
```

### Realtime

Flutter receives Socket.IO package status events and updates local package state.

### Provider Retry

Provider B intentionally fails its first attempt and subsequently succeeds.

### Provider Deduplication

Provider C produces duplicate data during processing, while only unique provider results are persisted.

### Concurrent Processing

Duplicate package-processing jobs were submitted during testing.

The system's concurrency/idempotency protections prevent duplicate provider-result persistence.

### Payment Idempotency

Submitting the same payment intent with the same idempotency key returns the same payment record.

### Payment Success

Payment confirmation transitions the payment to:

```text
SUCCEEDED
```

### Payment Failure

A simulated provider rejection transitions the payment to:

```text
FAILED
```

and records the failure reason.

### Webhook Deduplication

The first webhook is processed.

A repeated webhook with the same provider event ID is returned as a duplicate without repeating the business operation.

### Refund

A successful payment can be refunded and transitions to:

```text
REFUNDED
```

when the full amount has been refunded.

### Authorization

Unauthenticated access to protected package endpoints returns HTTP `401`.

Package queries additionally validate ownership to prevent IDOR access.

### Audit Logging

Package creation generates an `AuditLog` record containing the actor, action, entity, entity ID, context, and timestamp.

---

# Recommended Demonstration Flow

For assessment/demo purposes:

1. Start PostgreSQL and Redis.
2. Start the NestJS backend.
3. Launch the Flutter application.
4. Authenticate.
5. Create a task package.
6. Observe realtime package status transitions.
7. Demonstrate offline operation and synchronization.
8. Show Provider B timeout/retry behavior.
9. Query normalized provider results.
10. Show Provider C deduplication.
11. Demonstrate IDOR/authorization protection.
12. Create an idempotent payment intent.
13. Demonstrate successful payment confirmation.
14. Demonstrate failed payment handling.
15. Send a webhook twice and show duplicate protection.
16. Demonstrate a refund.
17. Query and show the audit trail.

---

# Production Considerations

Before deploying VectorFlow to production:

- Replace mock providers with real external integrations.
- Replace mock payments with a PCI-compliant payment provider.
- Restrict CORS to explicitly approved origins.
- Store uploaded files in managed object storage.
- Upgrade dependencies with known vulnerabilities.
- Add comprehensive unit and integration testing.
- Add end-to-end API tests.
- Add centralized structured logging.
- Add metrics and distributed tracing.
- Add monitoring and alerting.
- Store production secrets in a managed secret store.
- Add production-grade Redis persistence/high availability.
- Add PostgreSQL backup and recovery procedures.
- Add CI/CD security scanning.
- Apply production-specific rate limits.

---

# Known Limitations

This project is an assessment-oriented implementation and intentionally uses mock integrations for external providers and payments.

Current limitations include:

- External providers are simulated.
- Payments are simulated.
- Local development attachment storage is used.
- Dependency vulnerabilities require a controlled upgrade before production.
- Production observability infrastructure is not configured.
- Production secret management is not configured.

These limitations should be addressed before a real production deployment.