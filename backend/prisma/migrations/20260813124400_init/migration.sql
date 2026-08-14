-- CreateEnum
CREATE TYPE "PackagePriority" AS ENUM ('low', 'normal', 'high', 'urgent');

-- CreateEnum
CREATE TYPE "PackageStatus" AS ENUM ('draft', 'queued', 'submitted', 'processing', 'completed', 'failed');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RefreshToken" (
    "id" TEXT NOT NULL,
    "tokenHash" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "RefreshToken_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TaskPackage" (
    "id" TEXT NOT NULL,
    "clientId" TEXT,
    "userId" TEXT NOT NULL,
    "priority" "PackagePriority" NOT NULL DEFAULT 'normal',
    "notes" TEXT,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "status" "PackageStatus" NOT NULL DEFAULT 'submitted',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "TaskPackage_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PackageItem" (
    "id" TEXT NOT NULL,
    "packageId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "quantity" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "PackageItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Attachment" (
    "id" TEXT NOT NULL,
    "packageId" TEXT NOT NULL,
    "fileName" TEXT NOT NULL,
    "url" TEXT NOT NULL,
    "mimeType" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Attachment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PackageStatusHistory" (
    "id" TEXT NOT NULL,
    "packageId" TEXT NOT NULL,
    "status" "PackageStatus" NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PackageStatusHistory_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "TaskPackage_clientId_key" ON "TaskPackage"("clientId");

-- CreateIndex
CREATE INDEX "TaskPackage_userId_createdAt_idx" ON "TaskPackage"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "TaskPackage_status_idx" ON "TaskPackage"("status");

-- AddForeignKey
ALTER TABLE "RefreshToken" ADD CONSTRAINT "RefreshToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TaskPackage" ADD CONSTRAINT "TaskPackage_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PackageItem" ADD CONSTRAINT "PackageItem_packageId_fkey" FOREIGN KEY ("packageId") REFERENCES "TaskPackage"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Attachment" ADD CONSTRAINT "Attachment_packageId_fkey" FOREIGN KEY ("packageId") REFERENCES "TaskPackage"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PackageStatusHistory" ADD CONSTRAINT "PackageStatusHistory_packageId_fkey" FOREIGN KEY ("packageId") REFERENCES "TaskPackage"("id") ON DELETE CASCADE ON UPDATE CASCADE;
