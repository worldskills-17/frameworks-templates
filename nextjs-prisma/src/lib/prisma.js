import { PrismaMariaDb } from '@prisma/adapter-mariadb';
import { PrismaPg } from '@prisma/adapter-pg';
// Relative import with extension so plain Node (prisma/seed.mjs) can load this file too.
import { PrismaClient } from '../generated/prisma/client.ts';

// Prisma 7 connects through a driver adapter, chosen from the DATABASE_URL scheme so
// the same code serves MySQL and PostgreSQL (schema.prisma's provider must match).
// The database server is shared with every other competitor container, so both
// pools are capped at POOL_SIZE connections.
const POOL_SIZE = 5;

// MySQL (mariadb driver) options added to the URL:
// - allowPublicKeyRetrieval: MySQL 8 default auth (caching_sha2_password) over
//   plain TCP needs the server's RSA public key, which the driver only fetches
//   when allowed.
// - connectionLimit: the driver keeps its whole pool open.
const MYSQL_OPTIONS = { allowPublicKeyRetrieval: 'true', connectionLimit: String(POOL_SIZE) };

function createAdapter() {
  const raw = process.env.DATABASE_URL ?? '';
  let url;
  try {
    url = new URL(raw);
  } catch {
    // Unset or malformed URL: the first query reports the connection error.
    // Module load must not throw - `next build` imports this file.
    return new PrismaMariaDb(raw);
  }
  if (url.protocol === 'postgres:' || url.protocol === 'postgresql:') {
    return new PrismaPg({ connectionString: raw, max: POOL_SIZE });
  }
  for (const [key, value] of Object.entries(MYSQL_OPTIONS)) {
    if (!url.searchParams.has(key)) url.searchParams.set(key, value);
  }
  return new PrismaMariaDb(url.toString());
}

const globalForPrisma = globalThis;

const prisma = globalForPrisma.prisma ?? new PrismaClient({ adapter: createAdapter() });

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;

export default prisma;
