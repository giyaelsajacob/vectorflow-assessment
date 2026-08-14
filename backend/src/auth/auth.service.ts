import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';

import { PrismaService } from '../prisma/prisma.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  async register(dto: RegisterDto) {
    const email = dto.email.toLowerCase();

    const existing = await this.prisma.user.findUnique({
      where: { email },
    });

    if (existing) {
      throw new ConflictException(
        'Email already registered',
      );
    }

    const passwordHash =
        await bcrypt.hash(
      dto.password,
      12,
    );

    const user =
        await this.prisma.user.create({
      data: {
        name: dto.name,
        email,
        passwordHash,
      },
    });

    return this.issueTokens(
      user.id,
      user.email,
      user.role,
    );
  }

  async login(dto: LoginDto) {
    const user =
        await this.prisma.user.findUnique({
      where: {
        email:
          dto.email.toLowerCase(),
      },
    });

    if (
      !user ||
      !(await bcrypt.compare(
        dto.password,
        user.passwordHash,
      ))
    ) {
      throw new UnauthorizedException(
        'Invalid credentials',
      );
    }

    return this.issueTokens(
      user.id,
      user.email,
      user.role,
    );
  }

  async refresh(
    refreshToken: string,
  ) {
    try {
      const payload =
          await this.jwt.verifyAsync(
        refreshToken,
        {
          secret:
            process.env.JWT_REFRESH_SECRET ||
            'dev-refresh-secret',
        },
      );

      // Fetch the user again from DB so role changes
      // are reflected in newly issued tokens.
      const user =
          await this.prisma.user.findUnique({
        where: {
          id: payload.sub,
        },
      });

      if (!user) {
        throw new UnauthorizedException(
          'User not found',
        );
      }

      return this.issueTokens(
        user.id,
        user.email,
        user.role,
      );
    } catch {
      throw new UnauthorizedException(
        'Invalid refresh token',
      );
    }
  }

  private async issueTokens(
    userId: string,
    email: string,
    role: string,
  ) {
    const payload = {
      sub: userId,
      email,
      role,
    };

    const accessToken =
        await this.jwt.signAsync(
      payload,
      {
        secret:
          process.env.JWT_SECRET ||
          'dev-access-secret',

        expiresIn:
          '15m',
      },
    );

    const refreshToken =
        await this.jwt.signAsync(
      payload,
      {
        secret:
          process.env.JWT_REFRESH_SECRET ||
          'dev-refresh-secret',

        expiresIn:
          '7d',
      },
    );

    return {
      accessToken,
      refreshToken,
    };
  }
}