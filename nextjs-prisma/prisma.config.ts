// Prisma 7 configuration (replaces the datasource url in schema.prisma and the
// "prisma" section of package.json).
import { defineConfig } from 'prisma/config';

// The Prisma CLI no longer reads .env itself. Load it when present (local
// development); in the container DATABASE_URL comes from the image environment.
try {
  process.loadEnvFile();
} catch {
  // no .env file
}

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
    // Seed command run by `npx prisma db seed` (and on container start), e.g.
    // seed: 'node prisma/seed.mjs',
  },
  datasource: {
    // process.env rather than env(): env() throws when the variable is unset, and
    // `prisma generate` runs at image build time before DATABASE_URL exists.
    url: process.env.DATABASE_URL,
  },
});
