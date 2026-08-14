import {
  OnGatewayConnection,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { JwtService } from '@nestjs/jwt';
import { Server, Socket } from 'socket.io';

@WebSocketGateway({
  cors: {
    origin: '*',
    credentials: false,
  },
  transports: ['websocket', 'polling'],
})
export class RealtimeGateway implements OnGatewayConnection {
  constructor(private readonly jwt: JwtService) {}

  @WebSocketServer()
  server: Server;

  async handleConnection(client: Socket) {
    try {
      const token = client.handshake.auth?.token;

      const payload = await this.jwt.verifyAsync(token, {
        secret: process.env.JWT_SECRET || 'dev-access-secret',
      });

      await client.join(`user:${payload.sub}`);

      console.log(
        `Socket connected: ${client.id} -> user:${payload.sub}`,
      );
    } catch (error) {
      console.log(
        `Socket authentication failed: ${client.id}`,
      );

      client.disconnect();
    }
  }

  emitPackageStatus(
    userId: string,
    packageId: string,
    status: string,
  ) {
    this.server
      .to(`user:${userId}`)
      .emit('package.status.updated', {
        packageId,
        status,
      });

    console.log(
      `Realtime status emitted: ${packageId} -> ${status}`,
    );
  }
}