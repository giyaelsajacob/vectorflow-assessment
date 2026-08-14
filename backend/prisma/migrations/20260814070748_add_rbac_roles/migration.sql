/*
  Warnings:

  - A unique constraint covering the columns `[idempotencyKey]` on the table `Attachment` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateEnum
CREATE TYPE "Role" AS ENUM ('USER', 'REVIEWER', 'ADMIN');

-- AlterTable
ALTER TABLE "Attachment" ADD COLUMN     "idempotencyKey" TEXT,
ADD COLUMN     "size" INTEGER NOT NULL DEFAULT 0;

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "role" "Role" NOT NULL DEFAULT 'USER';

-- CreateIndex
CREATE UNIQUE INDEX "Attachment_idempotencyKey_key" ON "Attachment"("idempotencyKey");

-- CreateIndex
CREATE INDEX "Attachment_packageId_idx" ON "Attachment"("packageId");

-- CreateIndex
CREATE INDEX "PackageItem_packageId_idx" ON "PackageItem"("packageId");

-- CreateIndex
CREATE INDEX "PackageStatusHistory_packageId_createdAt_idx" ON "PackageStatusHistory"("packageId", "createdAt");

-- CreateIndex
CREATE INDEX "RefreshToken_userId_idx" ON "RefreshToken"("userId");

-- CreateIndex
CREATE INDEX "User_role_idx" ON "User"("role");
