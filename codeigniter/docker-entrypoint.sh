#!/bin/bash
# CodeIgniter 4 Docker Entrypoint
# Starts Apache immediately, runs migrations in background

echo "=== CodeIgniter 4 Container Starting ==="

# Run migrations in background so Apache starts immediately
(
    sleep 3
    # Marking mode: serve the restored database exactly as captured - never
    # migrate/seed/rebuild (a wrong-provenance image must not wipe marked data).
    if [ "${WS_MARKING:-0}" = "1" ]; then
        echo "  Marking mode (WS_MARKING=1) - serving restored database as-is; skipping migrations/seed"
        exit 0
    fi
    DB_HOST=$(grep "^database.default.hostname" /var/www/html/.env | cut -d'=' -f2 | tr -d ' ')
    DB_NAME=$(grep "^database.default.database" /var/www/html/.env | cut -d'=' -f2 | tr -d ' ')
    DB_USER=$(grep "^database.default.username" /var/www/html/.env | cut -d'=' -f2 | tr -d ' ')
    DB_PASS=$(grep "^database.default.password" /var/www/html/.env | cut -d'=' -f2 | tr -d ' ')
    export WS_DB_HOST="$DB_HOST" WS_DB_NAME="$DB_NAME" WS_DB_USER="$DB_USER" WS_DB_PASS="$DB_PASS"

    # --- Migration/seeder drift failsafe -----------------------------------
    # CodeIgniter never re-runs a migration whose version is already recorded
    # in the `migrations` table. A competitor who edits or deletes an
    # already-deployed migration (or changes seed classes) sees it work
    # locally, while the deployed schema silently stays stale. Detect that by
    # hashing app/Database/Migrations + app/Database/Seeds and comparing
    # against hashes stored in ws_migration_hashes (visible in phpMyAdmin).
    # On drift: drop all tables, re-migrate, re-seed - same as a local rebuild.

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
foreach (glob('app/Database/Migrations/*.php') as $f) {
    $v = explode('_', basename($f, '.php'), 2)[0];   // "2024-01-01-000000_Name" -> version
    $mig[$v] = hash_file('sha256', $f);
}
$sf = glob('app/Database/Seeds/*.php'); sort($sf);
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
foreach ($pdo->query('SELECT DISTINCT version FROM migrations') as $r) {
    $v = $r['version'];
    if (!isset($mig[$v])) { $drift = "deployed migration removed: $v"; break; }
    if (isset($stored[$v]) && $stored[$v] !== $mig[$v]) { $drift = "deployed migration edited: $v"; break; }
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
    foreach (glob('app/Database/Migrations/*.php') as $f) {
        $v = explode('_', basename($f, '.php'), 2)[0];
        $mig[$v] = hash_file('sha256', $f);
    }
    $sf = glob('app/Database/Seeds/*.php'); sort($sf);
    $s = '';
    foreach ($sf as $f) { $s .= basename($f) . ':' . hash_file('sha256', $f) . ';'; }

    $pdo->exec('CREATE TABLE IF NOT EXISTS ws_migration_hashes
        (filename VARCHAR(191) PRIMARY KEY, hash CHAR(64) NOT NULL)');
    $pdo->exec('DELETE FROM ws_migration_hashes');
    $ins = $pdo->prepare('INSERT INTO ws_migration_hashes (filename, hash) VALUES (?, ?)');
    foreach ($pdo->query('SELECT DISTINCT version FROM migrations') as $r) {
        if (isset($mig[$r['version']])) { $ins->execute([$r['version'], $mig[$r['version']]]); }
    }
    $ins->execute(['__seeders__', hash('sha256', $s)]);
} catch (Throwable $e) { fwrite(STDERR, 'hash store skipped: ' . $e->getMessage() . "\n"); }
PHPEOF

    cat > /tmp/ws-drop-tables.php << 'PHPEOF'
<?php
// Drop every table in the module database (drift rebuild).
$pdo = new PDO(
    'mysql:host=' . getenv('WS_DB_HOST') . ';dbname=' . getenv('WS_DB_NAME'),
    getenv('WS_DB_USER'), getenv('WS_DB_PASS'),
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_TIMEOUT => 5]
);
$pdo->exec('SET FOREIGN_KEY_CHECKS=0');
foreach ($pdo->query('SHOW TABLES')->fetchAll(PDO::FETCH_COLUMN) as $t) {
    $pdo->exec('DROP TABLE IF EXISTS `' . str_replace('`', '', $t) . '`');
}
$pdo->exec('SET FOREIGN_KEY_CHECKS=1');
PHPEOF

    run_seed() {
        if [ -f app/Database/Seeds/DatabaseSeeder.php ]; then
            php spark db:seed DatabaseSeeder 2>/dev/null && echo "  Seeding completed" || echo "  [WARN] db:seed failed - continuing"
        fi
    }

    cd /var/www/html
    MAX_TRIES=30
    TRIES=0
    while [ $TRIES -lt $MAX_TRIES ]; do
        STATE=$(php /tmp/ws-drift-check.php 2>/dev/null | grep -oE 'WS_(FIRST_BOOT|ADOPT|DRIFT|CLEAN)' | head -1)
        if [ -n "$STATE" ]; then
            echo "  Database connected"
            case "$STATE" in
                WS_DRIFT)
                    echo "  Schema drift detected (already-deployed migration or seeder changed)"
                    echo "  Rebuilding database..."
                    php /tmp/ws-drop-tables.php 2>/dev/null || echo "  [WARN] table drop failed"
                    php spark migrate --all 2>/dev/null && echo "  Migrations completed" || echo "  [WARN] Migration failed"
                    run_seed
                    ;;
                WS_FIRST_BOOT)
                    php spark migrate --all 2>/dev/null && echo "  Migrations completed" || echo "  [WARN] Migration failed"
                    run_seed
                    ;;
                *)
                    php spark migrate --all 2>/dev/null && echo "  Migrations completed" || echo "  [WARN] Migration failed"
                    ;;
            esac
            php /tmp/ws-drift-store.php 2>/dev/null
            break
        fi
        TRIES=$((TRIES + 1))
        [ $((TRIES % 10)) -eq 0 ] && echo "  Waiting for database... ($TRIES/$MAX_TRIES)"
        sleep 1
    done
) &

echo "Starting Apache..."
exec /usr/sbin/apache2ctl -D FOREGROUND
