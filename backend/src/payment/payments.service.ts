import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { randomUUID } from 'crypto';

import { PrismaService } from '../prisma/prisma.service';

import { ConfirmPaymentDto } from './dto/confirm-payment.dto';
import { CreatePaymentIntentDto } from './dto/create-payment-intent.dto';
import { PaymentWebhookDto } from './dto/webhook.dto';
import { RefundPaymentDto } from './dto/refund-payment.dto';

@Injectable()
export class PaymentsService {
  constructor(
    private readonly prisma: PrismaService,
  ) {}

  // ============================================================
  // CREATE PAYMENT INTENT
  // ============================================================

  async createIntent(
    userId: string,
    dto: CreatePaymentIntentDto,
    idempotencyKey: string,
  ) {
    if (!idempotencyKey) {
      throw new BadRequestException(
        'Idempotency-Key header is required.',
      );
    }

    const existing =
        await this.prisma.payment.findUnique({
      where: {
        idempotencyKey,
      },
    });

    if (existing) {
      if (existing.userId !== userId) {
        throw new ForbiddenException();
      }

      return existing;
    }

    const pkg =
        await this.prisma.taskPackage.findFirst({
      where: {
        id: dto.packageId,
        userId,
      },
    });

    if (!pkg) {
      throw new NotFoundException(
        'Package not found',
      );
    }

    return this.prisma.payment.create({
      data: {
        packageId: dto.packageId,
        userId,

        idempotencyKey,

        providerPaymentId:
          `mockpay_${randomUUID()}`,

        amountMinor:
          dto.amountMinor,

        currency:
          dto.currency.toUpperCase(),

        status:
          'REQUIRES_CONFIRMATION',
      },
    });
  }

  // ============================================================
  // GET PAYMENT
  // ============================================================

  async findOne(
    userId: string,
    paymentId: string,
  ) {
    const payment =
        await this.prisma.payment.findFirst({
      where: {
        id: paymentId,
        userId,
      },
    });

    if (!payment) {
      throw new NotFoundException(
        'Payment not found',
      );
    }

    return payment;
  }

  // ============================================================
  // CONFIRM PAYMENT
  // ============================================================

  async confirm(
    userId: string,
    paymentId: string,
    dto: ConfirmPaymentDto,
  ) {
    const payment =
        await this.findOne(
      userId,
      paymentId,
    );

    if (payment.status === 'SUCCEEDED') {
      return payment;
    }

    if (
      payment.status !==
      'REQUIRES_CONFIRMATION'
    ) {
      throw new BadRequestException(
        `Payment cannot be confirmed from status ${payment.status}`,
      );
    }

    await this.prisma.payment.update({
      where: {
        id: payment.id,
      },
      data: {
        status:
          'PROCESSING',
      },
    });

    if (!dto.simulateSuccess) {
      return this.prisma.payment.update({
        where: {
          id: payment.id,
        },
        data: {
          status:
            'FAILED',

          failureReason:
            'Mock payment provider rejected payment.',
        },
      });
    }

    return this.prisma.payment.update({
      where: {
        id: payment.id,
      },
      data: {
        status:
          'SUCCEEDED',

        failureReason:
          null,
      },
    });
  }

  // ============================================================
  // WEBHOOK
  //
  // Transaction guarantees:
  //
  // webhook event creation + payment update happen atomically.
  //
  // providerEventId UNIQUE prevents duplicate business effects.
  // ============================================================

  async handleWebhook(
    dto: PaymentWebhookDto,
  ) {
    const existingEvent =
        await this.prisma.paymentWebhookEvent.findUnique({
      where: {
        providerEventId:
          dto.providerEventId,
      },
    });

    if (existingEvent) {
      return {
        duplicate: true,
        eventId:
          existingEvent.id,
        status:
          existingEvent.status,
      };
    }

    const payment =
        await this.prisma.payment.findUnique({
      where: {
        providerPaymentId:
          dto.providerPaymentId,
      },
    });

    if (!payment) {
      throw new NotFoundException(
        'Payment not found',
      );
    }

    return this.prisma.$transaction(
      async (tx) => {
        const webhook =
            await tx.paymentWebhookEvent.create({
          data: {
            paymentId:
              payment.id,

            providerEventId:
              dto.providerEventId,

            eventType:
              dto.eventType,

            payload:
              dto as any,

            status:
              'RECEIVED',
          },
        });

        const nextStatus =
            dto.eventType ===
            'payment.succeeded'
              ? 'SUCCEEDED'
              : 'FAILED';

        await tx.payment.update({
          where: {
            id: payment.id,
          },
          data: {
            status:
              nextStatus,

            failureReason:
              nextStatus === 'FAILED'
                ? 'Mock provider webhook reported failure.'
                : null,
          },
        });

        await tx.paymentWebhookEvent.update({
          where: {
            id: webhook.id,
          },
          data: {
            status:
              'PROCESSED',

            processedAt:
              new Date(),
          },
        });

        return {
          duplicate: false,
          eventId:
            webhook.id,

          paymentStatus:
            nextStatus,
        };
      },
    );
  }

  // ============================================================
  // REFUND
  // ============================================================

  async refund(
    userId: string,
    paymentId: string,
    dto: RefundPaymentDto,
  ) {
    const payment =
        await this.findOne(
      userId,
      paymentId,
    );

    if (
      payment.status !==
      'SUCCEEDED'
    ) {
      throw new BadRequestException(
        'Only successful payments can be refunded.',
      );
    }

    const remaining =
        payment.amountMinor -
        payment.refundedAmount;

    if (
      dto.amountMinor >
      remaining
    ) {
      throw new BadRequestException(
        'Refund amount exceeds remaining refundable amount.',
      );
    }

    const newRefundedAmount =
        payment.refundedAmount +
        dto.amountMinor;

    return this.prisma.payment.update({
      where: {
        id: payment.id,
      },
      data: {
        refundedAmount:
          newRefundedAmount,

        status:
          newRefundedAmount ===
          payment.amountMinor
            ? 'REFUNDED'
            : 'SUCCEEDED',
      },
    });
  }
}