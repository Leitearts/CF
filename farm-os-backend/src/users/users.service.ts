import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  findByEmailOrPhone(identifier: string) {
    return this.prisma.user.findFirst({
      where: {
        deletedAt: null,
        OR: [{ email: identifier }, { phone: identifier }],
      },
    });
  }

  findById(id: string) {
    return this.prisma.user.findFirst({ where: { id, deletedAt: null } });
  }

  create(data: {
    fullName: string;
    email?: string;
    phone?: string;
    passwordHash: string;
  }) {
    return this.prisma.user.create({ data });
  }

  setRefreshTokenHash(userId: string, refreshTokenHash: string | null) {
    return this.prisma.user.update({
      where: { id: userId },
      data: { refreshTokenHash },
    });
  }

  setPasswordResetCode(
    userId: string,
    passwordResetCodeHash: string | null,
    passwordResetExpiresAt: Date | null,
  ) {
    return this.prisma.user.update({
      where: { id: userId },
      data: { passwordResetCodeHash, passwordResetExpiresAt },
    });
  }

  updatePassword(userId: string, passwordHash: string) {
    return this.prisma.user.update({
      where: { id: userId },
      data: {
        passwordHash,
        passwordResetCodeHash: null,
        passwordResetExpiresAt: null,
      },
    });
  }
}
