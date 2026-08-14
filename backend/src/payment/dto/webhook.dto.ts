import {
  IsIn,
  IsNotEmpty,
  IsString,
} from 'class-validator';

export class PaymentWebhookDto {
  @IsString()
  @IsNotEmpty()
  providerEventId: string;

  @IsString()
  @IsNotEmpty()
  providerPaymentId: string;

  @IsIn([
    'payment.succeeded',
    'payment.failed',
  ])
  eventType: string;
}