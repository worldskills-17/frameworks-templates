// Example seed script. Enable it in prisma.config.ts:
//   migrations: { seed: 'node prisma/seed.mjs' }
// then run `npx prisma db seed` locally. In the container it runs on boot
// whenever the seed command or any file under prisma/ (except schema.prisma)
// changes - a change resets the database first.
import prisma from '../src/lib/prisma.js';

await prisma.user.upsert({
  where: { email: 'demo@example.com' },
  update: {},
  create: { email: 'demo@example.com', name: 'Demo User' },
});

console.log(`Seeded users: ${await prisma.user.count()}`);
await prisma.$disconnect();
