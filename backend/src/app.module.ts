import { BullModule } from '@nestjs/bullmq';
import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import {
  ThrottlerGuard,
  ThrottlerModule,
} from '@nestjs/throttler';

import { AuditModule } from './audit/audit.module';
import { AuthModule } from './auth/auth.module';
import { PackagesModule } from './packages/packages.module';
import { PaymentsModule } from './payment/payments.module';
import { PrismaModule } from './prisma/prisma.module';
import { RealtimeModule } from './realtime/realtime.module';

@Module({
  imports: [
    PrismaModule,
    RealtimeModule,
    AuditModule,

    ThrottlerModule.forRoot([
      {
        ttl: 60000,
        limit: 100,
      },
    ]),

    BullModule.forRoot({
      connection: {
        host: process.env.REDIS_HOST || 'localhost',
        port: Number(
          process.env.REDIS_PORT || 6379,
        ),
      },
    }),

    AuthModule,
    PackagesModule,
    PaymentsModule,
  ],

  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}