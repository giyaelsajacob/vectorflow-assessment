# VectorFlow API Documentation

Base URL:

```text
http://localhost:3000/api
```

All protected endpoints require:

```http
Authorization: Bearer <access_token>
```

---

# 1. Authentication

## Register

```http
POST /api/auth/register
```

Creates a new user account.

Example request:

```json
{
  "name": "Test User",
  "email": "user@example.com",
  "password": "SecurePassword123!"
}
```

---

## Login

```http
POST /api/auth/login
```

Authenticates a user and returns authentication tokens.

Example request:

```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}
```

---

## Refresh Token

```http
POST /api/auth/refresh
```

Obtains a new access token using the refresh-token flow.

---

# 2. Task Packages

## Get Current User's Packages

```http
GET /api/packages
```

Requires authentication.

Only packages belonging to the authenticated user are returned.

---

## Get Single Package

```http
GET /api/packages/:id
```

Requires authentication.

The backend verifies both:

```text
package ID
+
authenticated user ID
```

This prevents IDOR access to another user's package.

---

## Create Package

```http
POST /api/packages
```

Requires authentication.

Example:

```json
{
  "clientId": "mobile-package-001",
  "priority": "normal",
  "notes": "Example package",
  "latitude": 25.2854,
  "longitude": 51.5310,
  "items": [
    {
      "name": "Example Item",
      "description": "Test item",
      "quantity": 1
    }
  ]
}
```

`clientId` provides idempotency protection against duplicate package creation.

The created package is queued for asynchronous processing using BullMQ.

Typical lifecycle:

```text
submitted
→ processing
→ waiting_for_external_result
→ ready
→ completed
```

---

## Upload Attachment

```http
POST /api/packages/:id/attachments
```

Requires authentication.

Content type:

```text
multipart/form-data
```

An optional/retry-safe idempotency key can be supplied according to the attachment endpoint implementation.

The backend validates package ownership before storing the attachment.

---

# 3. Reviewer Access

## Review Packages

```http
GET /api/packages/review/all
```

This endpoint is intended for authorized reviewer/privileged access according to the application's role guards.

---

# 4. Background Processing

Package processing is asynchronous.

Processing uses:

```text
NestJS
→ BullMQ
→ Redis
→ PackageProcessor
→ Provider A / B / C
→ PostgreSQL
```

Provider-specific responses are normalized before persistence.

Provider B demonstrates timeout/retry recovery.

Provider C demonstrates duplicate-result normalization.

---

# 5. Realtime Events

Socket.IO is used for realtime package status updates.

The backend emits package status information containing values equivalent to:

```json
{
  "packageId": "<package-uuid>",
  "status": "processing"
}
```

Possible processing statuses include:

```text
processing
waiting_for_external_result
ready
completed
failed
```

The authenticated Flutter client listens for these updates and updates its local state.

---

# 6. Payments

## Create Payment Intent

```http
POST /api/payments/intent
```

Requires authentication.

Required header:

```http
Idempotency-Key: <unique-key>
```

Example body:

```json
{
  "packageId": "<package-id>",
  "amountMinor": 10000,
  "currency": "QAR"
}
```

A repeated request using the same idempotency key returns the existing payment rather than creating a duplicate payment.

---

## Get Payment

```http
GET /api/payments/:id
```

Requires authentication.

Only the owner can retrieve the payment.

---

## Confirm Payment

```http
POST /api/payments/:id/confirm
```

Requires authentication.

Successful simulation:

```json
{
  "simulateSuccess": true
}
```

Typical result:

```text
SUCCEEDED
```

Failure simulation:

```json
{
  "simulateSuccess": false
}
```

Typical result:

```text
FAILED
```

The failure reason is persisted.

---

## Refund Payment

```http
POST /api/payments/:id/refund
```

Requires authentication.

Example:

```json
{
  "amountMinor": 10000
}
```

Only successful payments can be refunded.

The backend prevents refunding more than the remaining refundable amount.

A complete refund changes the status to:

```text
REFUNDED
```

---

# 7. Mock Payment Webhook

```http
POST /api/payments/webhook/mock
```

Processes simulated payment-provider events.

Example concept:

```json
{
  "providerEventId": "<unique-event-id>",
  "providerPaymentId": "<provider-payment-id>",
  "eventType": "payment.succeeded"
}
```

The first unique webhook event is processed.

If the same `providerEventId` is submitted again, it is treated as a duplicate and its business effect is not repeated.

Webhook persistence and payment status updates are handled transactionally.

---

# 8. Idempotency

VectorFlow applies idempotency at multiple layers.

| Operation | Protection |
|---|---|
| Package creation | Unique `clientId` |
| Attachment retry | Unique attachment idempotency key |
| BullMQ processing | Deterministic package job ID |
| Provider persistence | Composite unique constraint + upsert |
| Payment creation | Unique `Idempotency-Key` |
| Payment webhook | Unique provider event ID |

---

# 9. Authorization

Protected endpoints require a valid JWT.

Resource ownership is checked independently of resource IDs.

Examples:

```text
GET /api/packages/:id
GET /api/payments/:id
POST /api/packages/:id/attachments
POST /api/payments/:id/confirm
POST /api/payments/:id/refund
```

Users cannot access another user's protected resources simply by supplying their identifiers.

---

# 10. Rate Limiting

Global API throttling is configured using NestJS Throttler.

Current development configuration:

```text
100 requests / 60 seconds
```

Requests exceeding the configured limit are rejected by the throttling guard.

---

# 11. Validation

NestJS `ValidationPipe` is globally enabled with:

```text
whitelist = true
transform = true
forbidNonWhitelisted = true
```

Unexpected DTO properties are therefore rejected instead of silently entering application logic.

---

# 12. Security Headers

Helmet middleware is enabled globally.

This adds standard HTTP security headers to backend responses.

---

# 13. Error Responses

The API uses NestJS HTTP exceptions for expected failures.

Typical HTTP status codes include:

| Status | Meaning |
|---|---|
| 400 | Invalid request / invalid operation |
| 401 | Authentication required |
| 403 | Authenticated but operation forbidden |
| 404 | Resource not found |
| 429 | Rate limit exceeded |
| 500 | Unexpected server failure |

---

# 14. Health / Verification

The repository contains automated verification scripts:

### Windows

```powershell
powershell -ExecutionPolicy Bypass -File ./verify.ps1
```

### Linux / macOS

```bash
chmod +x verify.sh
./verify.sh
```

The scripts verify core infrastructure, Prisma state, compilation, authentication protection, and dependency-security status.

---

# 15. Important Security Notes

This project is an assessment implementation.

The following must be changed before production use:

- Replace mock payment processing.
- Replace mock external providers.
- Restrict CORS to approved origins.
- Move attachments to secure object storage.
- Use managed production secrets.
- Resolve dependency-security findings through controlled upgrades.
- Add production observability and alerting.
- Add comprehensive automated integration and end-to-end testing.