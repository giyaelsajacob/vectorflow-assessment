-- CreateEnum
CREATE TYPE "AuditAction" AS ENUM ('PACKAGE_CREATED', 'PACKAGE_STATUS_CHANGED', 'ATTACHMENT_UPLOADED', 'PAYMENT_CREATED', 'PAYMENT_CONFIRMED', 'PAYMENT_FAILED', 'PAYMENT_REFUNDED', 'ROLE_CHANGED');

-- CreateTable
CREATE TABLE "AuditLog" (
    "id" TEXT NOT NULL,
    "actorId" TEXT,
    "action" "AuditAction" NOT NULL,
    "entity" TEXT NOT NULL,
    "entityId" TEXT NOT NULL,
    "oldValue" JSONB,
    "newValue" JSONB,
    "context" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "AuditLog_actorId_idx" ON "AuditLog"("actorId");

-- CreateIndex
CREATE INDEX "AuditLog_entity_entityId_idx" ON "AuditLog"("entity", "entityId");

-- CreateIndex
CREATE INDEX "AuditLog_action_idx" ON "AuditLog"("action");

-- CreateIndex
CREATE INDEX "AuditLog_createdAt_idx" ON "AuditLog"("createdAt");
