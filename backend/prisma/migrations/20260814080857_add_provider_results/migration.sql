-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "PackageStatus" ADD VALUE 'waiting_for_external_result';
ALTER TYPE "PackageStatus" ADD VALUE 'ready';

-- CreateTable
CREATE TABLE "ProviderResult" (
    "id" TEXT NOT NULL,
    "packageId" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "externalId" TEXT,
    "status" TEXT NOT NULL,
    "score" DOUBLE PRECISION,
    "message" TEXT,
    "rawHash" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ProviderResult_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ProviderResult_packageId_idx" ON "ProviderResult"("packageId");

-- CreateIndex
CREATE INDEX "ProviderResult_provider_idx" ON "ProviderResult"("provider");

-- CreateIndex
CREATE UNIQUE INDEX "ProviderResult_packageId_provider_externalId_key" ON "ProviderResult"("packageId", "provider", "externalId");

-- AddForeignKey
ALTER TABLE "ProviderResult" ADD CONSTRAINT "ProviderResult_packageId_fkey" FOREIGN KEY ("packageId") REFERENCES "TaskPackage"("id") ON DELETE CASCADE ON UPDATE CASCADE;
