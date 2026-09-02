import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

export class ResetPasswordDto {
  @ApiProperty({ description: 'Email or phone number used at registration' })
  @IsString()
  identifier: string;

  @ApiProperty({ description: 'One-time reset code sent to the user' })
  @IsString()
  resetCode: string;

  @ApiProperty()
  @IsString()
  @MinLength(8, { message: 'Password must be at least 8 characters.' })
  newPassword: string;
}
