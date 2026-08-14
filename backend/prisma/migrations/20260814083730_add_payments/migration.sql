-- CreateEnum
CREATE TYPE "PaymentStatus" AS ENUM ('PENDING', 'REQUIRES_CONFIRMATION', 'PROCESSING', 'SUCCEEDED', 'FAILED', 'REFUND_PENDING', 'REFUNDED');

-- CreateEnum
CREATE TYPE "WebhookStatus" AS ENUM ('RECEIVED', 'PROCESSED', 'IGNORED', 'FAILED');

-- CreateTable
CREATE TABLE "Payment" (
    "id" TEXT NOT NULL,
    "packageId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "idempotencyKey" TEXT NOT NULL,
    "providerPaymentId" TEXT NOT NULL,
    "amountMinor" INTEGER NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'QAR',
    "status" "PaymentStatus" NOT NULL DEFAULT 'PENDING',
    "failureReason" TEXT,
    "refundedAmount" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Payment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PaymentWebhookEvent" (
    "id" TEXT NOT NULL,
    "paymentId" TEXT NOT NULL,
    "providerEventId" TEXT NOT NULL,
    "eventType" TEXT NOT NULL,
    "status" "WebhookStatus" NOT NULL DEFAULT 'RECEIVED',
    "payload" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "processedAt" TIMESTAMP(3),

    CONSTRAINT "PaymentWebhookEvent_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Payment_idempotencyKey_key" ON "Payment"("idempotencyKey");

-- CreateIndex
CREATE UNIQUE INDEX "Payment_providerPaymentId_key" ON "Payment"("providerPaymentId");

-- CreateIndex
CREATE INDEX "Payment_packageId_idx" ON "Payment"("packageId");

-- CreateIndex
CREATE INDEX "Payment_userId_idx" ON "Payment"("userId");

-- CreateIndex
CREATE INDEX "Payment_status_idx" ON "Payment"("status");

-- CreateIndex
CREATE UNIQUE INDEX "PaymentWebhookEvent_providerEventId_key" ON "PaymentWebhookEvent"("providerEventId");

-- CreateIndex
CREATE INDEX "PaymentWebhookEvent_paymentId_idx" ON "PaymentWebhookEvent"("paymentId");

-- CreateIndex
CREATE INDEX "PaymentWebhookEvent_status_idx" ON "PaymentWebhookEvent"("status");

-- AddForeignKey
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_packageId_fkey" FOREIGN KEY ("packageId") REFERENCES "TaskPackage"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PaymentWebhookEvent" ADD CONSTRAINT "PaymentWebhookEvent_paymentId_fkey" FOREIGN KEY ("paymentId") REFERENCES "Payment"("id") ON DELETE CASCADE ON UPDATE CASCADE;
