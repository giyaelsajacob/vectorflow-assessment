import {
  Body,
  Controller,
  Get,
  Headers,
  Param,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';

import { JwtAuthGuard } from '../auth/jwt-auth.guard';

import { ConfirmPaymentDto } from './dto/confirm-payment.dto';
import { CreatePaymentIntentDto } from './dto/create-payment-intent.dto';
import { PaymentWebhookDto } from './dto/webhook.dto';
import { RefundPaymentDto } from './dto/refund-payment.dto';
import { PaymentsService } from './payments.service';

@Controller('payments')
export class PaymentsController {
  constructor(
    private readonly payments:
      PaymentsService,
  ) {}

  // ============================================================
  // CREATE PAYMENT INTENT
  // ============================================================

  @Post('intent')
  @UseGuards(JwtAuthGuard)
  createIntent(
    @Req() req: any,

    @Headers('idempotency-key')
    idempotencyKey: string,

    @Body()
    dto: CreatePaymentIntentDto,
  ) {
    return this.payments.createIntent(
      req.user.userId,
      dto,
      idempotencyKey,
    );
  }

  // ============================================================
  // GET PAYMENT
  // ============================================================

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  findOne(
    @Req() req: any,
    @Param('id') id: string,
  ) {
    return this.payments.findOne(
      req.user.userId,
      id,
    );
  }

  // ============================================================
  // CONFIRM
  // ============================================================

  @Post(':id/confirm')
  @UseGuards(JwtAuthGuard)
  confirm(
    @Req() req: any,

    @Param('id')
    id: string,

    @Body()
    dto: ConfirmPaymentDto,
  ) {
    return this.payments.confirm(
      req.user.userId,
      id,
      dto,
    );
  }

  // ============================================================
  // REFUND
  // ============================================================

  @Post(':id/refund')
  @UseGuards(JwtAuthGuard)
  refund(
    @Req() req: any,

    @Param('id')
    id: string,

    @Body()
    dto: RefundPaymentDto,
  ) {
    return this.payments.refund(
      req.user.userId,
      id,
      dto,
    );
  }

  // ============================================================
  // MOCK PROVIDER WEBHOOK
  //
  // Deliberately NOT JWT protected because real payment
  // providers call webhooks server-to-server.
  //
  // Later we can add a mock webhook signature.
  // ============================================================

  @Post('webhook/mock')
  webhook(
    @Body()
    dto: PaymentWebhookDto,
  ) {
    return this.payments.handleWebhook(
      dto,
    );
  }
}