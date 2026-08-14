import { IsBoolean } from 'class-validator';

export class ConfirmPaymentDto {
  @IsBoolean()
  simulateSuccess: boolean;
}