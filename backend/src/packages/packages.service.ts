import { InjectQueue } from '@nestjs/bullmq';
import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Queue } from 'bullmq';
import { unlink } from 'fs/promises';

import { AuditService } from '../audit/audit.service';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePackageDto } from './dto/create-package.dto';

@Injectable()
export class PackagesService {
  constructor(
    private readonly prisma: PrismaService,

    @InjectQueue('package-processing')
    private readonly queue: Queue,

    private readonly audit: AuditService,
  ) {}

  async create(
    userId: string,
    dto: CreatePackageDto,
  ) {
    if (dto.clientId) {
      const existing =
        await this.prisma.taskPackage.findUnique({
          where: {
            clientId: dto.clientId,
          },
          include: {
            items: true,
            attachments: true,
            statusHistory: true,
          },
        });

      if (existing) {
        if (existing.userId !== userId) {
          throw new ForbiddenException(
            'Package client ID belongs to another user.',
          );
        }

        return existing;
      }
    }

    const pkg =
      await this.prisma.taskPackage.create({
        data: {
          userId,
          clientId: dto.clientId,
          priority: dto.priority,
          notes: dto.notes,
          latitude: dto.latitude,
          longitude: dto.longitude,

          items: {
            create: dto.items.map(
              (item) => ({
                name: item.name,
                description: item.description,
                quantity: item.quantity,
              }),
            ),
          },

          statusHistory: {
            create: {
              status: 'submitted',
            },
          },
        },

        include: {
          items: true,
          attachments: true,
          statusHistory: true,
        },
      });

    // AUDIT: PACKAGE CREATED
    await this.audit.log({
      actorId: userId,
      action: 'PACKAGE_CREATED',
      entity: 'TaskPackage',
      entityId: pkg.id,
      newValue: {
        status: pkg.status,
        priority: pkg.priority,
        itemCount: pkg.items.length,
      },
      context: 'Package created by authenticated user',
    });

    await this.queue.add(
      'process-package',
      {
        packageId: pkg.id,
        userId,
      },
      {
        attempts: 3,

        backoff: {
          type: 'exponential',
          delay: 2000,
        },

        removeOnComplete: true,

        jobId: `package-${pkg.id}`,
      },
    );

    return pkg;
  }

  findAll(
    userId: string,
  ) {
    return this.prisma.taskPackage.findMany({
      where: {
        userId,
      },

      include: {
        items: true,
        attachments: true,
      },

      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  async findOne(
    userId: string,
    id: string,
  ) {
    const pkg =
      await this.prisma.taskPackage.findFirst({
        where: {
          id,
          userId,
        },

        include: {
          items: true,
          attachments: true,

          statusHistory: {
            orderBy: {
              createdAt: 'asc',
            },
          },
        },
      });

    if (!pkg) {
      throw new NotFoundException(
        'Package not found',
      );
    }

    return pkg;
  }

  async uploadAttachment({
    userId,
    packageId,
    file,
    idempotencyKey,
  }: {
    userId: string;
    packageId: string;
    file: Express.Multer.File;
    idempotencyKey?: string;
  }) {
    const pkg =
      await this.prisma.taskPackage.findUnique({
        where: {
          id: packageId,
        },
      });

    if (!pkg) {
      await this.safeDeleteFile(
        file.path,
      );

      throw new NotFoundException(
        'Package not found',
      );
    }

    if (pkg.userId !== userId) {
      await this.safeDeleteFile(
        file.path,
      );

      throw new ForbiddenException(
        'You cannot upload attachments to this package.',
      );
    }

    if (idempotencyKey) {
      const existing =
        await this.prisma.attachment.findUnique({
          where: {
            idempotencyKey,
          },
        });

      if (existing) {
        await this.safeDeleteFile(
          file.path,
        );

        return existing;
      }
    }

    const attachment =
      await this.prisma.attachment.create({
        data: {
          packageId,
          fileName: file.originalname,
          url: file.path,
          mimeType: file.mimetype,
          size: file.size,
          idempotencyKey:
            idempotencyKey ?? null,
        },
      });

    // AUDIT: ATTACHMENT UPLOADED
    await this.audit.log({
      actorId: userId,
      action: 'ATTACHMENT_UPLOADED',
      entity: 'Attachment',
      entityId: attachment.id,
      newValue: {
        packageId,
        fileName: attachment.fileName,
        mimeType: attachment.mimeType,
        size: attachment.size,
      },
      context: 'Attachment uploaded to package',
    });

    return attachment;
  }

  private async safeDeleteFile(
    filePath: string,
  ) {
    try {
      await unlink(filePath);
    } catch {
      // Ignore cleanup errors.
    }
  }
}