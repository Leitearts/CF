import { ApiPropertyOptional, ApiProperty } from '@nestjs/swagger';
import {
  IsEmail,
  IsOptional,
  IsString,
  MinLength,
  ValidateIf,
} from 'class-validator';

export class RegisterDto {
  @ApiProperty()
  @IsString()
  @MinLength(2)
  fullName: string;

  @ApiPropertyOptional()
  @ValidateIf((o) => !o.phone)
  @IsEmail({}, { message: 'A valid email is required if phone is not provided.' })
  email?: string;

  @ApiPropertyOptional()
  @ValidateIf((o) => !o.email)
  @IsString({ message: 'A valid phone number is required if email is not provided.' })
  phone?: string;

  @ApiProperty()
  @IsString()
  @MinLength(8, { message: 'Password must be at least 8 characters.' })
  password: string;
}
