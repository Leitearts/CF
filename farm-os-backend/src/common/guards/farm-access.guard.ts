import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

/**
 * Central enforcement point for "a farmer must never access another farmer's
 * data": every route with a :farmId param goes through this guard, which
 * checks the caller has an active FarmMember row for that farm and attaches
 * the resolved role onto the request for RolesGuard to use downstream.
 *
 * This intentionally lives at the guard layer rather than being re-checked
 * inside each service, so farm isolation can't be accidentally skipped by a
 * new controller.
 */
@Injectable()
export class FarmAccessGuard implements CanActivate {
  constructor(private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const farmId: string | undefined = request.params?.farmId;
    const userId: string | undefined = request.user?.id;

    if (!farmId || !userId) {
      throw new ForbiddenException('Farm context or authenticated user missing.');
    }

    const membership = await this.prisma.farmMember.findFirst({
      where: { farmId, userId, deletedAt: null },
      include: { role: true },
    });

    if (!membership) {
      throw new ForbiddenException('You do not have access to this farm.');
    }

    request.farmRole = membership.role.name;
    request.farmId = farmId;
    return true;
  }
}
