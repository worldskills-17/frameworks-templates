import { PrismaMariaDb } from '@prisma/adapter-mariadb';
// Relative import with extension so plain Node (prisma/seed.mjs) can load this file too.
import { PrismaClient } from '../generated/prisma/client.ts';

// Prisma 7 connects through a driver adapter; MySQL uses the mariadb driver.
// Driver options added to the URL handed to the adapter:
// - allowPublicKeyRetrieval: MySQL 8 default auth (caching_sha2_password) over
//   plain TCP needs the server's RSA public key, which the driver only fetches
//   when allowed.
// - connectionLimit: the driver keeps its whole pool open; the MySQL server is
//   shared with every other competitor container.
const DRIVER_OPTIONS = { allowPublicKeyRetrieval: 'true', connectionLimit: '5' };

function connectionString() {
  const raw = process.env.DATABASE_URL ?? '';
  try {
    const url = new URL(raw);
    for (const [key, value] of Object.entries(DRIVER_OPTIONS)) {
      if (!url.searchParams.has(key)) url.searchParams.set(key, value);
    }
    return url.toString();
  } catch {
    // Unset or malformed URL: the first query reports the connection error.
    // Module load must not throw - `next build` imports this file.
    return raw;
  }
}

const globalForPrisma = globalThis;

const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({ adapter: new PrismaMariaDb(connectionString()) });

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;

export default prisma;
