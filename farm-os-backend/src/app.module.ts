import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { PrismaModule } from './database/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { FarmsModule } from './farms/farms.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ThrottlerModule.forRoot([
      {
        ttl: 60_000, // 1 minute window
        limit: 100, // generous default; auth endpoints apply a stricter limit locally
      },
    ]),
    PrismaModule,
    AuthModule,
    UsersModule,
    FarmsModule,
    // Livestock/Feed/Drugs/Equipment/Finance/Reports/Dashboard/Alerts/Audit
    // modules land in Sprints 2-4, per the approved development strategy.
  ],
})
export class AppModule {}
