import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaMariaDb } from '@prisma/adapter-mariadb';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../generated/prisma/client';

// Prisma 7 connects through a driver adapter, chosen from the DATABASE_URL scheme so
// the same code serves MySQL and PostgreSQL (schema.prisma's provider must match):
// - postgres:// or postgresql:// -> @prisma/adapter-pg
// - mysql:// -> @prisma/adapter-mariadb (the MariaDB driver also speaks MySQL)
function createAdapter(): PrismaMariaDb | PrismaPg {
  if (!process.env.DATABASE_URL) {
    throw new Error('DATABASE_URL is not set');
  }
  const url = new URL(process.env.DATABASE_URL);
  if (url.protocol === 'postgres:' || url.protocol === 'postgresql:') {
    return new PrismaPg({ connectionString: process.env.DATABASE_URL });
  }
  // MySQL 8 caching_sha2_password needs the server RSA key on non-TLS connections
  if (!url.searchParams.has('allowPublicKeyRetrieval')) {
    url.searchParams.set('allowPublicKeyRetrieval', 'true');
  }
  return new PrismaMariaDb(url.toString());
}

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  constructor() {
    super({ adapter: createAdapter() });
  }

  async onModuleInit() {
    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
