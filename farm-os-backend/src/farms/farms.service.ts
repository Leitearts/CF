import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { CreateFarmDto } from './dto/create-farm.dto';
import { UpdateFarmDto } from './dto/update-farm.dto';

@Injectable()
export class FarmsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Creates the farm and, in the same transaction, makes the creator a
   * 'farmer' (owner) FarmMember — so "create farm" always leaves the system
   * in a consistent, immediately-usable state with no follow-up step needed.
   */
  async create(ownerUserId: string, dto: CreateFarmDto) {
    const farmerRole = await this.prisma.role.findUnique({
      where: { name: 'farmer' },
    });
    if (!farmerRole) {
      throw new NotFoundException(
        'Role "farmer" is missing — run the database seed before creating farms.',
      );
    }

    return this.prisma.$transaction(async (tx) => {
      const farm = await tx.farm.create({
        data: { ...dto, ownerUserId },
      });

      await tx.farmMember.create({
        data: {
          farmId: farm.id,
          userId: ownerUserId,
          roleId: farmerRole.id,
        },
      });

      return farm;
    });
  }

  /** Farms the given user belongs to (owner or invited member). */
  findAllForUser(userId: string) {
    return this.prisma.farm.findMany({
      where: {
        deletedAt: null,
        members: { some: { userId, deletedAt: null } },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  async findOne(farmId: string) {
    const farm = await this.prisma.farm.findFirst({
      where: { id: farmId, deletedAt: null },
    });
    if (!farm) {
      throw new NotFoundException('Farm not found.');
    }
    return farm;
  }

  async update(farmId: string, dto: UpdateFarmDto) {
    await this.findOne(farmId); // 404s early if it doesn't exist / isn't accessible
    return this.prisma.farm.update({
      where: { id: farmId },
      data: dto,
    });
  }
}
