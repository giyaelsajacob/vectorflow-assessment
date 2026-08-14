# VectorFlow Flutter

Production-oriented Flutter client for the VectorFlow technical assessment.

## Included

- Feature-first Clean Architecture style structure
- Riverpod state management and dependency injection
- GoRouter navigation
- Dio REST client
- JWT access/refresh token handling
- Flutter Secure Storage
- Drift SQLite offline operation queue
- Connectivity-aware sync service
- Socket.IO realtime status updates
- Authentication
- Dashboard
- Create Task Package
- Attachments
- Location
- Package details
- Offline queue
- History
- Profile/settings
- Centralized failure classes
- Environment configuration using --dart-define

## Run

1. Install Flutter.
2. Open this folder in Android Studio.
3. Run:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api --dart-define=SOCKET_URL=http://10.0.2.2:3000
```

For a physical Android device, replace `10.0.2.2` with your computer's LAN IP.

## Backend contract expected

Authentication:
- POST /auth/register
- POST /auth/login
- POST /auth/refresh

Packages:
- GET /packages
- GET /packages/:id
- POST /packages
- POST /packages/:id/attachments

Profile:
- GET /users/me
- PATCH /users/me

Socket.IO event:
- `package.status.updated`

Example event:

```json
{
  "packageId": "uuid",
  "status": "processing"
}
```

## Notes

This project intentionally isolates API, local persistence, repositories and presentation state so the backend can be connected without redesigning Flutter.
