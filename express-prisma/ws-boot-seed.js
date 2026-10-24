// Boot-time seed failsafe. Runs after `prisma db push` (which keeps the
// schema in sync on every deploy - Prisma has no stale-migration trap).
// The server never exposes a shell, so `prisma db seed` must run here:
//   - first boot with a seed configured  -> seed
//   - seed files changed since last boot -> full reset (db push --force-reset)
//     then reseed, mirroring what the competitor does locally
// The seed command is read from prisma.config.ts (migrations.seed) with the
// same loader the Prisma 7 CLI uses. Watched files: the seed command +
// everything under prisma/ except schema.prisma. Hash is stored in the
// ws_seed_hash table (MySQL or PostgreSQL, from the DATABASE_URL scheme).
// Always exits 0 - the app must start regardless.
//
// `prisma db push --accept-data-loss` drops tables that are not in the schema,
// ws_seed_hash included, so the stored hash is read before the push:
//   node ws-boot-seed.js --before-push   (saves the stored hash to a file)
//   npx prisma db push --accept-data-loss
//   node ws-boot-seed.js                 (seeds if needed, rewrites the hash)
'use strict';
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const os = require('os');
const { execSync } = require('child_process');

const appDir = process.cwd();
const beforePush = process.argv.includes('--before-push');
const handoffFile = path.join(os.tmpdir(), 'ws-seed-hash-before-push');

// Skip notices are printed by the main run only, not by --before-push
function notice(msg) {
  if (!beforePush) console.log(msg);
}

function walk(dir, files) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, files);
    else if (e.isFile() && e.name !== 'schema.prisma') files.push(p);
  }
}

function appRequire(name, extraPaths) {
  return require(require.resolve(name, { paths: [...(extraPaths || []), appDir] }));
}

// Hash table access for the database in DATABASE_URL, using the driver its Prisma
// adapter already depends on (the generated Prisma Client is TypeScript at a
// project-defined path, so it is not loaded here):
// - PostgreSQL: pg (@prisma/adapter-pg)
// - MySQL: mariadb (@prisma/adapter-mariadb)
const CREATE_TABLE = 'CREATE TABLE IF NOT EXISTS ws_seed_hash (id INT PRIMARY KEY, hash CHAR(64) NOT NULL)';

async function openHashStore(databaseUrl) {
  const u = new URL(databaseUrl);
  if (u.protocol === 'postgres:' || u.protocol === 'postgresql:') {
    const { Client } = appRequire('pg', [path.join(appDir, 'node_modules', '@prisma', 'adapter-pg')]);
    const client = new Client({ connectionString: databaseUrl });
    await client.connect();
    await client.query(CREATE_TABLE);
    return {
      get: async () => {
        const res = await client.query('SELECT hash FROM ws_seed_hash WHERE id = 1');
        return res.rows.length ? res.rows[0].hash : null;
      },
      set: (hash) => client.query(
        'INSERT INTO ws_seed_hash (id, hash) VALUES (1, $1) ON CONFLICT (id) DO UPDATE SET hash = EXCLUDED.hash', [hash]),
      close: () => client.end()
    };
  }
  const mariadb = appRequire('mariadb', [path.join(appDir, 'node_modules', '@prisma', 'adapter-mariadb')]);
  const conn = await mariadb.createConnection({
    host: u.hostname,
    port: u.port ? Number(u.port) : 3306,
    user: decodeURIComponent(u.username),
    password: decodeURIComponent(u.password),
    database: decodeURIComponent(u.pathname.replace(/^\//, '')),
    allowPublicKeyRetrieval: true
  });
  await conn.query(CREATE_TABLE);
  return {
    get: async () => {
      const rows = await conn.query('SELECT hash FROM ws_seed_hash WHERE id = 1');
      return rows.length ? rows[0].hash : null;
    },
    set: (hash) => conn.query('REPLACE INTO ws_seed_hash (id, hash) VALUES (1, ?)', [hash]),
    close: () => conn.end()
  };
}

async function withHashStore(databaseUrl, fn) {
  const store = await openHashStore(databaseUrl);
  try {
    return await fn(store);
  } finally {
    await store.close();
  }
}

(async () => {
  try {
    if (beforePush && fs.existsSync(handoffFile)) fs.unlinkSync(handoffFile);
    const { loadConfigFromFile } = appRequire('@prisma/config', [path.join(appDir, 'node_modules', 'prisma')]);
    const loaded = await loadConfigFromFile({ configRoot: appDir });
    if (loaded.error) {
      notice('[WARN] could not load prisma.config.ts (' + loaded.error._tag + ') - skipping seed step');
      return;
    }
    const config = loaded.config;
    const seedCmd = config.migrations && config.migrations.seed;
    if (!seedCmd) {
      const pkg = JSON.parse(fs.readFileSync(path.join(appDir, 'package.json'), 'utf8'));
      if (pkg.prisma && pkg.prisma.seed) {
        notice('[WARN] package.json "prisma.seed" is ignored by Prisma 7 - move it to migrations.seed in prisma.config.ts');
      }
      notice('No seed command configured - skipping seed step');
      return;
    }
    // Loading the config runs its dotenv import, so .env values are available
    const databaseUrl = (config.datasource && config.datasource.url) || process.env.DATABASE_URL;
    if (!databaseUrl) {
      notice('[WARN] no datasource url configured - skipping seed step');
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

    const readStored = () => withHashStore(databaseUrl, (store) => store.get());

    if (beforePush) {
      fs.writeFileSync(handoffFile, (await readStored()) || '');
      return;
    }
    let stored;
    if (fs.existsSync(handoffFile)) {
      stored = fs.readFileSync(handoffFile, 'utf8') || null;
      fs.unlinkSync(handoffFile);
    } else {
      stored = await readStored();
    }
    if (stored === hash) {
      console.log('Seed up to date');
      await withHashStore(databaseUrl, (store) => store.set(hash));
      return;
    }
    if (stored !== null) {
      console.log('Seed files changed - resetting database...');
      execSync('npx prisma db push --force-reset --accept-data-loss', { stdio: 'inherit' });
    }
    console.log('Running prisma db seed...');
    try {
      execSync('npx prisma db seed', { stdio: 'inherit' });
    } catch (e) {
      console.log('[WARN] prisma db seed failed - continuing');
    }
    await withHashStore(databaseUrl, (store) => store.set(hash));
  } catch (e) {
    console.log('[WARN] seed check skipped' + (beforePush ? ' (before push)' : '') + ': ' + e.message);
  }
})();
