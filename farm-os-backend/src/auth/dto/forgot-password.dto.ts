import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export class ForgotPasswordDto {
  @ApiProperty({ description: 'Email or phone number used at registration' })
  @IsString()
  identifier: string;
}
