import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  welcomeHtml(): string {
    return '<div style="padding: 2rem; font-family: system-ui, sans-serif;"><h1 style="color: #e0234e; font-size: 2rem; font-weight: bold;">NestJS + Prisma - It works!</h1><p style="margin-top: 1rem; color: #666;">Try <code>GET /users</code> or <code>POST /users</code> with a JSON body.</p></div>';
  }
}
