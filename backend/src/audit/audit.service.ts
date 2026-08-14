import { Injectable } from '@nestjs/common';
import { AuditAction, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AuditService {
  constructor(private readonly prisma: PrismaService) {}

  async log(params: {
    actorId?: string;
    action: AuditAction;
    entity: string;
    entityId: string;
    oldValue?: unknown;
    newValue?: unknown;
    context?: string;
  }) {
    return this.prisma.auditLog.create({
      data: {
        actorId: params.actorId,
        action: params.action,
        entity: params.entity,
        entityId: params.entityId,
        oldValue:
          params.oldValue === undefined
            ? undefined
            : (params.oldValue as Prisma.InputJsonValue),
        newValue:
          params.newValue === undefined
            ? undefined
            : (params.newValue as Prisma.InputJsonValue),
        context: params.context,
      },
    });
  }
}