import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Headers,
  Param,
  Post,
  Req,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';

import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';

import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';

import { CreatePackageDto } from './dto/create-package.dto';
import { PackagesService } from './packages.service';

@Controller('packages')
@UseGuards(JwtAuthGuard, RolesGuard)
export class PackagesController {
  constructor(
    private readonly packages: PackagesService,
  ) {}

  // ============================================================
  // GET CURRENT USER'S PACKAGES
  // ============================================================

  @Get()
  findAll(
    @Req() req: any,
  ) {
    return this.packages.findAll(
      req.user.userId,
    );
  }

  // ============================================================
  // RBAC TEST ENDPOINT
  //
  // USER       -> 403
  // REVIEWER   -> allowed
  // ADMIN      -> allowed
  //
  // IMPORTANT:
  // Static routes must stay BEFORE @Get(':id')
  // ============================================================

  @Get('review/all')
  @Roles(
    'REVIEWER',
    'ADMIN',
  )
  reviewPackages() {
    return {
      message:
        'Reviewer/Admin access granted',
    };
  }

  // ============================================================
  // CREATE PACKAGE
  // ============================================================

  @Post()
  create(
    @Req() req: any,
    @Body() dto: CreatePackageDto,
  ) {
    return this.packages.create(
      req.user.userId,
      dto,
    );
  }

  // ============================================================
  // ATTACHMENT UPLOAD
  //
  // JWT protected
  // Ownership checked in PackagesService
  // JPG/JPEG/PNG/PDF only
  // Maximum 10 MB
  // Supports Idempotency-Key
  // ============================================================

  @Post(':id/attachments')
  @UseInterceptors(
    FileInterceptor(
      'file',
      {
        storage: diskStorage({
          destination: './uploads',

          filename: (
            req,
            file,
            callback,
          ) => {
            const uniqueName =
              `${Date.now()}-${Math.round(
                Math.random() *
                  1_000_000_000,
              )}`;

            const extension =
              extname(
                file.originalname,
              );

            callback(
              null,
              `${uniqueName}${extension}`,
            );
          },
        }),

        limits: {
          fileSize:
            10 * 1024 * 1024,
        },

        fileFilter: (
          req,
          file,
          callback,
        ) => {
          const allowedMimeTypes = [
            'image/jpeg',
            'image/png',
            'application/pdf',
          ];

          if (
            !allowedMimeTypes.includes(
              file.mimetype,
            )
          ) {
            return callback(
              new BadRequestException(
                'Only JPG, JPEG, PNG and PDF files are allowed.',
              ),
              false,
            );
          }

          callback(
            null,
            true,
          );
        },
      },
    ),
  )
  async uploadAttachment(
    @Req() req: any,

    @Param('id')
    packageId: string,

    @UploadedFile()
    file: any,

    @Headers('idempotency-key')
    idempotencyKey?: string,
  ) {
    if (!file) {
      throw new BadRequestException(
        'Attachment file is required.',
      );
    }

    return this.packages.uploadAttachment({
      userId:
        req.user.userId,

      packageId,

      file,

      idempotencyKey,
    });
  }

  // ============================================================
  // GET SINGLE PACKAGE
  //
  // Keep this AFTER static routes like /review/all.
  //
  // PackagesService.findOne() must scope by:
  //
  // id + authenticated userId
  //
  // This prevents IDOR.
  // ============================================================

  @Get(':id')
  findOne(
    @Req() req: any,
    @Param('id') id: string,
  ) {
    return this.packages.findOne(
      req.user.userId,
      id,
    );
  }
}