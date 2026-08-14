#!/usr/bin/env bash

set -e

echo "========================================"
echo " VectorFlow Automated Verification"
echo "========================================"

echo ""
echo "[1] Docker containers"
docker ps

echo ""
echo "[2] PostgreSQL readiness"
docker exec vectorflow_backend-postgres-1 \
  pg_isready -U vectorflow -d vectorflow

echo ""
echo "[3] Prisma migration status"
npx prisma migrate status

echo ""
echo "[4] Prisma schema validation"
npx prisma validate

echo ""
echo "[5] Backend build"
npm run build

echo ""
echo "[6] Unauthorized access test"

STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  http://localhost:3000/api/packages)

if [ "$STATUS" = "401" ]; then
  echo "PASS: Unauthorized request rejected with HTTP 401."
else
  echo "FAIL: Expected HTTP 401 but received $STATUS."
  exit 1
fi

echo ""
echo "[7] Dependency security scan"
npm audit --audit-level=high || true

echo ""
echo "========================================"
echo " VectorFlow verification completed"
echo "========================================"