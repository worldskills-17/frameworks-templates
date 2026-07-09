#!/bin/bash
set -e
echo "=== Laravel Container Starting ==="

# Brief sleep to let DB stabilize on fresh deploys (no PHP-based ping needed)
sleep 3

php artisan storage:link --force 2>/dev/null || true
php artisan config:clear 2>/dev/null || true
php artisan route:clear 2>/dev/null || true
php artisan view:clear 2>/dev/null || true

# --- Migration/seeder drift failsafe ---------------------------------------
# Laravel never re-runs a migration whose filename is already recorded in the
# `migrations` table. A competitor who edits or deletes an already-deployed
# migration (or changes seed data) sees it work locally via migrate:fresh,
# while the deployed schema silently stays stale. Detect that here by hashing
# database/migrations + database/seeders and comparing against hashes stored
# in ws_migration_hashes (visible in phpMyAdmin). On drift: rebuild the
# schema from scratch and reseed - the same thing the competitor does locally.

DB_HOST_VAL=$(grep -m1 '^DB_HOST=' .env | cut -d= -f2-)
DB_NAME_VAL=$(grep -m1 '^DB_DATABASE=' .env | cut -d= -f2-)
DB_USER_VAL=$(grep -m1 '^DB_USERNAME=' .env | cut -d= -f2-)
DB_PASS_VAL=$(grep -m1 '^DB_PASSWORD=' .env | cut -d= -f2-)
export WS_DB_HOST="$DB_HOST_VAL" WS_DB_NAME="$DB_NAME_VAL" WS_DB_USER="$DB_USER_VAL" WS_DB_PASS="$DB_PASS_VAL"

cat > /tmp/ws-drift-check.php << 'PHPEOF'
<?php
// Prints exactly one state: WS_NO_DB | WS_FIRST_BOOT | WS_ADOPT | WS_DRIFT | WS_CLEAN
try {
    $pdo = new PDO(
        'mysql:host=' . getenv('WS_DB_HOST') . ';dbname=' . getenv('WS_DB_NAME'),
        getenv('WS_DB_USER'), getenv('WS_DB_PASS'),
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_TIMEOUT => 5]
    );
} catch (Throwable $e) { echo "WS_NO_DB\n"; exit(0); }

$mig = [];
foreach (glob('database/migrations/*.php') as $f) {
    $mig[basename($f, '.php')] = hash_file('sha256', $f);
}
$sf = glob('database/seeders/*.php'); sort($sf);
$s = '';
foreach ($sf as $f) { $s .= basename($f) . ':' . hash_file('sha256', $f) . ';'; }
$seedHash = hash('sha256', $s);

if (!$pdo->query("SHOW TABLES LIKE 'migrations'")->fetchAll()) { echo "WS_FIRST_BOOT\n"; exit(0); }
if (!$pdo->query("SHOW TABLES LIKE 'ws_migration_hashes'")->fetchAll()) { echo "WS_ADOPT\n"; exit(0); }

$stored = [];
foreach ($pdo->query('SELECT filename, hash FROM ws_migration_hashes') as $r) {
    $stored[$r['filename']] = $r['hash'];
}
$drift = '';
foreach ($pdo->query('SELECT migration FROM migrations') as $r) {
    $m = $r['migration'];
    if (!isset($mig[$m])) { $drift = "deployed migration removed: $m"; break; }
    if (isset($stored[$m]) && $stored[$m] !== $mig[$m]) { $drift = "deployed migration edited: $m"; break; }
}
if (!$drift && isset($stored['__seeders__']) && $stored['__seeders__'] !== $seedHash) {
    $drift = 'seeders changed';
}
echo $drift ? "WS_DRIFT ($drift)\n" : "WS_CLEAN\n";
PHPEOF

cat > /tmp/ws-drift-store.php << 'PHPEOF'
<?php
// Record current migration/seeder hashes; failures are non-fatal.
try {
    $pdo = new PDO(
        'mysql:host=' . getenv('WS_DB_HOST') . ';dbname=' . getenv('WS_DB_NAME'),
        getenv('WS_DB_USER'), getenv('WS_DB_PASS'),
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_TIMEOUT => 5]
    );
    $mig = [];
    foreach (glob('database/migrations/*.php') as $f) {
        $mig[basename($f, '.php')] = hash_file('sha256', $f);
    }
    $sf = glob('database/seeders/*.php'); sort($sf);
    $s = '';
    foreach ($sf as $f) { $s .= basename($f) . ':' . hash_file('sha256', $f) . ';'; }

    $pdo->exec('CREATE TABLE IF NOT EXISTS ws_migration_hashes
        (filename VARCHAR(191) PRIMARY KEY, hash CHAR(64) NOT NULL)');
    $pdo->exec('DELETE FROM ws_migration_hashes');
    $ins = $pdo->prepare('INSERT INTO ws_migration_hashes (filename, hash) VALUES (?, ?)');
    foreach ($pdo->query('SELECT migration FROM migrations') as $r) {
        if (isset($mig[$r['migration']])) { $ins->execute([$r['migration'], $mig[$r['migration']]]); }
    }
    $ins->execute(['__seeders__', hash('sha256', $s)]);
} catch (Throwable $e) { fwrite(STDERR, 'hash store skipped: ' . $e->getMessage() . "\n"); }
PHPEOF

# Marking mode: serve the restored database exactly as captured - never
# migrate/seed/rebuild (a wrong-provenance image must not wipe marked data).
if [ "${WS_MARKING:-0}" = "1" ]; then
    echo "Marking mode (WS_MARKING=1) - serving restored database as-is; skipping migrations/drift rebuild"
else
STATE=""
for i in 1 2 3 4 5 6 7 8 9 10; do
    STATE=$(php /tmp/ws-drift-check.php 2>/dev/null | grep -oE 'WS_(FIRST_BOOT|ADOPT|DRIFT|CLEAN)' | head -1)
    [ -n "$STATE" ] && break
    echo "  waiting for database ($i/10)..."
    sleep 3
done

case "$STATE" in
    WS_DRIFT)
        echo "Schema drift detected (already-deployed migration or seeder changed)"
        echo "Rebuilding database: migrate:fresh + seed..."
        php artisan migrate:fresh --force 2>&1 | tail -3
        php artisan db:seed --force 2>&1 | tail -3 || echo "  [WARN] db:seed failed - continuing"
        ;;
    WS_FIRST_BOOT)
        echo "Running migrations (first boot)..."
        for i in 1 2 3 4 5 6 7 8 9 10; do
            if php artisan migrate --force 2>&1 | tee /tmp/migrate.log | grep -qE "Nothing to migrate|migrated"; then
                echo "  OK"
                break
            fi
            echo "  retry $i/10..."
            sleep 3
        done
        php artisan db:seed --force 2>&1 | tail -3 || echo "  [WARN] db:seed failed - continuing"
        ;;
    *)
        # WS_ADOPT (pre-failsafe database - adopt current files as baseline),
        # WS_CLEAN, or empty (DB unreachable - keep legacy retry behaviour)
        echo "Running migrations..."
        for i in 1 2 3 4 5 6 7 8 9 10; do
            if php artisan migrate --force 2>&1 | tee /tmp/migrate.log | grep -qE "Nothing to migrate|migrated"; then
                echo "  OK"
                break
            fi
            echo "  retry $i/10..."
            sleep 3
        done
        ;;
esac

# Record the now-deployed state for the next boot's drift comparison
php /tmp/ws-drift-store.php 2>/dev/null || true

# Schema sanity check
EXPECTED="users sessions migrations"
MISSING=""
for t in $EXPECTED; do
    php artisan tinker --execute "DB::table(\"$t\")->limit(1)->get();" >/dev/null 2>&1 || MISSING="$MISSING $t"
done
if [ -n "$MISSING" ]; then
    echo "[WARN] Missing tables:$MISSING - running migrate:fresh"
    php artisan migrate:fresh --force 2>&1 | tail -5
fi
fi

echo "Starting Apache..."
exec /usr/sbin/apache2ctl -D FOREGROUND
