import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Put,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { FarmsService } from './farms.service';
import { CreateFarmDto } from './dto/create-farm.dto';
import { UpdateFarmDto } from './dto/update-farm.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { FarmAccessGuard } from '../common/guards/farm-access.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/jwt.strategy';

@ApiTags('farms')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('farms')
export class FarmsController {
  constructor(private readonly farmsService: FarmsService) {}

  @Post()
  create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateFarmDto) {
    return this.farmsService.create(user.id, dto);
  }

  @Get()
  findAll(@CurrentUser() user: AuthenticatedUser) {
    return this.farmsService.findAllForUser(user.id);
  }

  // :farmId routes go through FarmAccessGuard in addition to JwtAuthGuard,
  // enforcing that the caller belongs to this specific farm.
  @Get(':farmId')
  @UseGuards(FarmAccessGuard)
  findOne(@Param('farmId') farmId: string) {
    return this.farmsService.findOne(farmId);
  }

  @Put(':farmId')
  @UseGuards(FarmAccessGuard)
  update(@Param('farmId') farmId: string, @Body() dto: UpdateFarmDto) {
    return this.farmsService.update(farmId, dto);
  }
}
