import { BullModule } from '@nestjs/bullmq';
import { Module } from '@nestjs/common';

import { ProvidersService } from '../providers/providers.service';
import { PackageProcessor } from './package.processor';
import { PackagesController } from './packages.controller';
import { PackagesService } from './packages.service';

@Module({
  imports: [
    BullModule.registerQueue({
      name: 'package-processing',
    }),
  ],

  controllers: [
    PackagesController,
  ],

  providers: [
    PackagesService,
    PackageProcessor,
    ProvidersService,
  ],
})
export class PackagesModule {}