import {
  IsInt,
  IsNotEmpty,
  IsPositive,
  IsString,
  IsUUID,
} from 'class-validator';

export class CreatePaymentIntentDto {
  @IsUUID()
  packageId: string;

  @IsInt()
  @IsPositive()
  amountMinor: number;

  @IsString()
  @IsNotEmpty()
  currency: string;
}