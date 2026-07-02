// Boot-time seed failsafe. Runs after `prisma db push` (which keeps the
// schema in sync on every deploy - Prisma has no stale-migration trap).
// The server never exposes a shell, so `prisma db seed` must run here:
//   - first boot with a seed configured  -> seed
//   - seed files changed since last boot -> full reset (db push --force-reset)
//     then reseed, mirroring what the competitor does locally
// Watched files: the package.json "prisma.seed" command + everything under
// prisma/ except schema.prisma. Hash is stored in the ws_seed_hash table
// (visible in phpMyAdmin). Always exits 0 - the app must start regardless.
'use strict';
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execSync } = require('child_process');

function walk(dir, files) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, files);
    else if (e.isFile() && e.name !== 'schema.prisma') files.push(p);
  }
}

(async () => {
  try {
    const pkg = JSON.parse(fs.readFileSync(path.join(process.cwd(), 'package.json'), 'utf8'));
    const seedCmd = pkg.prisma && pkg.prisma.seed;
    if (!seedCmd) {
      console.log('No prisma.seed configured - skipping seed step');
      return;
    }
    const h = crypto.createHash('sha256');
    h.update('cmd:' + seedCmd + ';');
    const files = [];
    if (fs.existsSync('prisma')) walk('prisma', files);
    for (const f of files) {
      h.update(f + ':' + crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex') + ';');
    }
    const hash = h.digest('hex');

    const { PrismaClient } = require(path.join(process.cwd(), 'node_modules', '@prisma/client'));
    const prisma = new PrismaClient();
    await prisma.$executeRawUnsafe(
      'CREATE TABLE IF NOT EXISTS ws_seed_hash (id INT PRIMARY KEY, hash CHAR(64) NOT NULL)');
    const rows = await prisma.$queryRawUnsafe('SELECT hash FROM ws_seed_hash WHERE id = 1');
    const stored = rows.length ? rows[0].hash : null;
    if (stored === hash) {
      console.log('Seed up to date');
      await prisma.$disconnect();
      return;
    }
    if (stored !== null) {
      console.log('Seed files changed - resetting database...');
      await prisma.$disconnect();
      execSync('npx prisma db push --force-reset --accept-data-loss --skip-generate', { stdio: 'inherit' });
    } else {
      await prisma.$disconnect();
    }
    console.log('Running prisma db seed...');
    try {
      execSync('npx prisma db seed', { stdio: 'inherit' });
    } catch (e) {
      console.log('[WARN] prisma db seed failed - continuing');
    }
    const prisma2 = new PrismaClient();
    await prisma2.$executeRawUnsafe(
      'CREATE TABLE IF NOT EXISTS ws_seed_hash (id INT PRIMARY KEY, hash CHAR(64) NOT NULL)');
    await prisma2.$executeRawUnsafe("REPLACE INTO ws_seed_hash (id, hash) VALUES (1, '" + hash + "')");
    await prisma2.$disconnect();
  } catch (e) {
    console.log('[WARN] seed check skipped: ' + e.message);
  }
})();
