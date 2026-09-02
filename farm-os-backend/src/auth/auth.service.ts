import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { randomInt } from 'crypto';
import { UsersService } from '../users/users.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

@Injectable()
export class AuthService {
  private readonly saltRounds = parseInt(
    process.env.BCRYPT_SALT_ROUNDS ?? '12',
    10,
  );

  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
  ) {}

  async register(dto: RegisterDto) {
    const existing = dto.email || dto.phone
      ? await this.usersService.findByEmailOrPhone((dto.email ?? dto.phone)!)
      : null;
    if (existing) {
      throw new ConflictException(
        'An account with this email or phone already exists.',
      );
    }

    const passwordHash = await bcrypt.hash(dto.password, this.saltRounds);
    const user = await this.usersService.create({
      fullName: dto.fullName,
      email: dto.email,
      phone: dto.phone,
      passwordHash,
    });

    const tokens = await this.issueTokens(user.id, user.email, user.phone);
    return { user: this.sanitizeUser(user), ...tokens };
  }

  async login(dto: LoginDto) {
    const user = await this.usersService.findByEmailOrPhone(dto.identifier);
    if (!user) {
      throw new UnauthorizedException('Invalid credentials.');
    }
    const passwordMatches = await bcrypt.compare(dto.password, user.passwordHash);
    if (!passwordMatches) {
      throw new UnauthorizedException('Invalid credentials.');
    }

    const tokens = await this.issueTokens(user.id, user.email, user.phone);
    return { user: this.sanitizeUser(user), ...tokens };
  }

  async logout(userId: string) {
    await this.usersService.setRefreshTokenHash(userId, null);
    return { message: 'Logged out successfully.' };
  }

  async refresh(refreshToken: string) {
    let payload: { sub: string };
    try {
      payload = this.jwtService.verify(refreshToken, {
        secret: process.env.JWT_REFRESH_SECRET ?? 'change-me-refresh-secret',
      });
    } catch {
      throw new UnauthorizedException('Invalid or expired refresh token.');
    }

    const user = await this.usersService.findById(payload.sub);
    if (!user || !user.refreshTokenHash) {
      throw new UnauthorizedException('Refresh token has been revoked.');
    }

    const matches = await bcrypt.compare(refreshToken, user.refreshTokenHash);
    if (!matches) {
      throw new UnauthorizedException('Refresh token has been revoked.');
    }

    // Rotate: issue a brand new pair, invalidating the one just used.
    const tokens = await this.issueTokens(user.id, user.email, user.phone);
    return tokens;
  }

  async forgotPassword(identifier: string) {
    const user = await this.usersService.findByEmailOrPhone(identifier);
    // Always return a generic success message, whether or not the account
    // exists, so this endpoint can't be used to enumerate registered users.
    if (!user) {
      return {
        message:
          'If an account exists for this email/phone, a reset code has been sent.',
      };
    }

    const resetCode = randomInt(100000, 999999).toString(); // 6-digit code
    const resetCodeHash = await bcrypt.hash(resetCode, this.saltRounds);
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes

    await this.usersService.setPasswordResetCode(user.id, resetCodeHash, expiresAt);

    // TODO (Sprint 2+): wire to an actual email/SMS provider. Logged here so
    // the flow is fully testable end-to-end before that integration exists.
    // eslint-disable-next-line no-console
    console.log(`[DEV ONLY] Password reset code for ${identifier}: ${resetCode}`);

    return {
      message:
        'If an account exists for this email/phone, a reset code has been sent.',
    };
  }

  async resetPassword(identifier: string, resetCode: string, newPassword: string) {
    const user = await this.usersService.findByEmailOrPhone(identifier);
    if (
      !user ||
      !user.passwordResetCodeHash ||
      !user.passwordResetExpiresAt ||
      user.passwordResetExpiresAt < new Date()
    ) {
      throw new UnauthorizedException('Reset code is invalid or has expired.');
    }

    const codeMatches = await bcrypt.compare(resetCode, user.passwordResetCodeHash);
    if (!codeMatches) {
      throw new UnauthorizedException('Reset code is invalid or has expired.');
    }

    const passwordHash = await bcrypt.hash(newPassword, this.saltRounds);
    await this.usersService.updatePassword(user.id, passwordHash);
    return { message: 'Password has been reset. Please log in.' };
  }

  private async issueTokens(
    userId: string,
    email?: string | null,
    phone?: string | null,
  ): Promise<TokenPair> {
    const payload = { sub: userId, email: email ?? undefined, phone: phone ?? undefined };

    const accessToken = this.jwtService.sign(payload, {
      secret: process.env.JWT_ACCESS_SECRET ?? 'change-me-access-secret',
      expiresIn: process.env.JWT_ACCESS_EXPIRY ?? '15m',
    });
    const refreshToken = this.jwtService.sign(payload, {
      secret: process.env.JWT_REFRESH_SECRET ?? 'change-me-refresh-secret',
      expiresIn: process.env.JWT_REFRESH_EXPIRY ?? '30d',
    });

    const refreshTokenHash = await bcrypt.hash(refreshToken, this.saltRounds);
    await this.usersService.setRefreshTokenHash(userId, refreshTokenHash);

    return { accessToken, refreshToken };
  }

  private sanitizeUser(user: {
    id: string;
    fullName: string;
    email: string | null;
    phone: string | null;
  }) {
    return {
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
    };
  }
}
