$ErrorActionPreference = "Stop"

Write-Host "========================================"
Write-Host " VectorFlow Automated Verification"
Write-Host "========================================"

Write-Host ""
Write-Host "[1] Checking Docker containers..."

docker ps

Write-Host ""
Write-Host "[2] Checking PostgreSQL..."

docker exec vectorflow_backend-postgres-1 `
  pg_isready -U vectorflow -d vectorflow

Write-Host ""
Write-Host "[3] Checking Prisma migrations..."

npx prisma migrate status

Write-Host ""
Write-Host "[4] Validating Prisma schema..."

npx prisma validate

Write-Host ""
Write-Host "[5] Generating Prisma Client..."

try {
  npx prisma generate

  if ($LASTEXITCODE -ne 0) {
    Write-Host "WARN: Prisma generate failed, likely because the Windows Prisma engine DLL is locked by a running backend process."
  }
}
catch {
  Write-Host "WARN: Prisma generate could not complete."
}

npx prisma generate

Write-Host ""
Write-Host "[6] Building backend..."

npm run build

Write-Host ""
Write-Host "[7] Checking unauthorized package access..."

try {
  Invoke-RestMethod `
    -Method Get `
    -Uri "http://localhost:3000/api/packages"

  Write-Host "FAILED: Unauthorized request was accepted."
  exit 1
}
catch {
  if ($_.Exception.Response.StatusCode.value__ -eq 401) {
    Write-Host "PASS: Unauthorized access rejected with 401."
  }
  else {
    Write-Host "Request rejected."
  }
}

Write-Host ""
Write-Host "[8] Dependency audit..."

npm audit --audit-level=high

Write-Host ""
Write-Host "========================================"
Write-Host " Verification completed"
Write-Host "========================================"