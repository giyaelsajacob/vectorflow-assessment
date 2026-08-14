import {
  Processor,
  WorkerHost,
} from '@nestjs/bullmq';

import { Job } from 'bullmq';

import {
  PrismaService,
} from '../prisma/prisma.service';

import {
  ProvidersService,
} from '../providers/providers.service';

import {
  RealtimeGateway,
} from '../realtime/realtime.gateway';

@Processor('package-processing')
export class PackageProcessor
  extends WorkerHost {
  constructor(
    private readonly prisma:
      PrismaService,

    private readonly realtime:
      RealtimeGateway,

    private readonly providers:
      ProvidersService,
  ) {
    super();
  }

  async process(
    job: Job<{
      packageId: string;
      userId: string;
    }>,
  ) {
    const {
      packageId,
      userId,
    } = job.data;

    // ========================================================
    // ATOMIC CONCURRENCY CLAIM
    //
    // Only one worker is allowed to move the package into
    // PROCESSING.
    //
    // If another worker has already claimed it, count = 0.
    // ========================================================

    const claim =
        await this.prisma.taskPackage.updateMany({
      where: {
        id: packageId,

        status: {
          in: [
            'submitted',
            'queued',
          ],
        },
      },

      data: {
        status:
          'processing',
      },
    });

    if (claim.count === 0) {
      console.log(
        `PACKAGE ${packageId}: already claimed by another worker`,
      );

      return {
        packageId,
        status:
          'already_processing',
      };
    }

    try {
      // ======================================================
      // RECORD PROCESSING HISTORY
      // ======================================================

      await this.prisma.packageStatusHistory.create({
        data: {
          packageId,
          status:
            'processing',
        },
      });

      this.realtime.emitPackageStatus(
        userId,
        packageId,
        'processing',
      );

      console.log(
        `PACKAGE ${packageId}: processing`,
      );

      // ======================================================
      // WAITING FOR EXTERNAL PROVIDERS
      // ======================================================

      await this.updateStatus(
        packageId,
        userId,
        'waiting_for_external_result',
      );

      // ======================================================
      // PROVIDER A + B + C
      // ======================================================

      const providerResults =
          await this.providers.processPackage(
        packageId,
      );

      // ======================================================
      // NORMALIZED RESULTS → POSTGRESQL
      // ======================================================

      for (
        const result
        of providerResults
      ) {
        await this.prisma.providerResult.upsert({
          where: {
            packageId_provider_externalId: {
              packageId,

              provider:
                result.provider,

              externalId:
                result.externalId,
            },
          },

          update: {
            status:
              result.status,

            score:
              result.score,

            message:
              result.message,
          },

          create: {
            packageId,

            provider:
              result.provider,

            externalId:
              result.externalId,

            status:
              result.status,

            score:
              result.score,

            message:
              result.message,
          },
        });
      }

      // ======================================================
      // READY
      // ======================================================

      await this.updateStatus(
        packageId,
        userId,
        'ready',
      );

      await new Promise(
        (resolve) =>
          setTimeout(
            resolve,
            700,
          ),
      );

      // ======================================================
      // COMPLETED
      // ======================================================

      await this.updateStatus(
        packageId,
        userId,
        'completed',
      );

      return {
        packageId,

        status:
          'completed',

        providerResults:
          providerResults.length,
      };
    } catch (error) {
      console.error(
        `Package processing failed: ${packageId}`,
        error,
      );

      // Only mark FAILED if this worker actually claimed it.
      await this.updateStatus(
        packageId,
        userId,
        'failed',
      );

      throw error;
    }
  }

  // ==========================================================
  // STATUS UPDATE
  // ==========================================================

  private async updateStatus(
    packageId: string,
    userId: string,
    status:
      | 'waiting_for_external_result'
      | 'ready'
      | 'completed'
      | 'failed',
  ) {
    await this.prisma.taskPackage.update({
      where: {
        id:
          packageId,
      },

      data: {
        status,

        statusHistory: {
          create: {
            status,
          },
        },
      },
    });

    this.realtime.emitPackageStatus(
      userId,
      packageId,
      status,
    );

    console.log(
      `PACKAGE ${packageId}: ${status}`,
    );
  }
}