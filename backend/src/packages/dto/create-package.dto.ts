import {
  IsArray,
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export enum PackagePriorityDto {
  low = 'low',
  normal = 'normal',
  high = 'high',
  urgent = 'urgent',
}

class PackageItemDto {
  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsInt()
  @Min(1)
  quantity: number;
}

export class CreatePackageDto {
  @IsOptional()
  @IsString()
  clientId?: string;

  @IsEnum(PackagePriorityDto)
  priority: PackagePriorityDto;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsNumber()
  latitude?: number;

  @IsOptional()
  @IsNumber()
  longitude?: number;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PackageItemDto)
  items: PackageItemDto[];
}
