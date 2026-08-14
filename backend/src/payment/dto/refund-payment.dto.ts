import {
  IsInt,
  IsPositive,
} from 'class-validator';

export class RefundPaymentDto {
  @IsInt()
  @IsPositive()
  amountMinor: number;
}