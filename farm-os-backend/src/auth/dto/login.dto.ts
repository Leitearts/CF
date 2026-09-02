import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export class LoginDto {
  @ApiProperty({ description: 'Email or phone number used at registration' })
  @IsString()
  identifier: string;

  @ApiProperty()
  @IsString()
  password: string;
}
