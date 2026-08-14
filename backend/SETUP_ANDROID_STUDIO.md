# Android Studio Setup

You can run both Flutter and backend from Android Studio terminals.

Recommended layout:

```text
Development/
  vectorflow_flutter/
  vectorflow_backend/
```

## Backend terminal

Open Android Studio -> Terminal.

Navigate:

```bash
cd path\to\vectorflow_backend
```

Then:

```bash
docker compose up -d
npm install
copy .env.example .env
npx prisma generate
npx prisma migrate dev --name init
npm run start:dev
```

Leave this terminal running.

Expected message:

```text
Nest application successfully started
```

## Flutter terminal

Open a second terminal and go to Flutter project.

For an Android emulator:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api --dart-define=SOCKET_URL=http://10.0.2.2:3000
```

For a physical phone, use the laptop's IPv4 address instead of `10.0.2.2`.
