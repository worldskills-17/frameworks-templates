// Prisma 7 configuration (replaces the datasource url in schema.prisma and
// the "prisma" section of package.json). The Prisma CLI does not load .env
// by itself, hence the dotenv import.
import 'dotenv/config';
import { defineConfig } from 'prisma/config';

export default defineConfig({
    schema: 'prisma/schema.prisma',
    migrations: {
        path: 'prisma/migrations',
        // Seed command run by `npx prisma db seed` (and on container start), e.g.
        // seed: 'node prisma/seed.js',
    },
    datasource: {
        // process.env (not env()) so `prisma generate` works without a database URL
        url: process.env.DATABASE_URL,
    },
});
