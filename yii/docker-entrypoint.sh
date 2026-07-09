#!/bin/bash
# Yii2 Docker Entrypoint
# Starts Apache immediately, runs migrations in background

echo "=== Yii2 Container Starting ==="

# Run migrations in background so Apache starts immediately
(
    sleep 3

    # Marking mode: serve the restored database exactly as captured - never
    # migrate/rebuild (a wrong-provenance image must not wipe marked data).
    if [ "${WS_MARKING:-0}" = "1" ]; then
        echo "  Marking mode (WS_MARKING=1) - serving restored database as-is; skipping migrations"
        exit 0
    fi

    # --- Migration drift failsafe ------------------------------------------
    # Yii never re-runs a migration whose class name is already recorded in
    # the `migration` table. A competitor who edits or deletes an
    # already-deployed migration sees it work locally (migrate/fresh), while
    # the deployed schema silently stays stale. Detect that by hashing
    # migrations/*.php and comparing against hashes stored in
    # ws_migration_hashes (visible in phpMyAdmin). On drift:
    # `yii migrate/fresh` rebuilds the schema from scratch.

    cat > /tmp/ws-drift-check.php << 'PHPEOF'
<?php
// Prints exactly one state: WS_NO_DB | WS_FIRST_BOOT | WS_ADOPT | WS_DRIFT | WS_CLEAN
try {
    $pdo = new PDO(getenv('DB_DSN'), getenv('DB_USERNAME'), getenv('DB_PASSWORD'),
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_TIMEOUT => 5]);
} catch (Throwable $e) { echo "WS_NO_DB\n"; exit(0); }

$mig = [];
foreach (glob('migrations/*.php') as $f) {
    $mig[basename($f, '.php')] = hash_file('sha256', $f);
}

if (!$pdo->query("SHOW TABLES LIKE 'migration'")->fetchAll()) { echo "WS_FIRST_BOOT\n"; exit(0); }
if (!$pdo->query("SHOW TABLES LIKE 'ws_migration_hashes'")->fetchAll()) { echo "WS_ADOPT\n"; exit(0); }

$stored = [];
foreach ($pdo->query('SELECT filename, hash FROM ws_migration_hashes') as $r) {
    $stored[$r['filename']] = $r['hash'];
}
$drift = '';
foreach ($pdo->query("SELECT version FROM migration WHERE version <> 'm000000_000000_base'") as $r) {
    $m = $r['version'];
    if (!isset($mig[$m])) { $drift = "deployed migration removed: $m"; break; }
    if (isset($stored[$m]) && $stored[$m] !== $mig[$m]) { $drift = "deployed migration edited: $m"; break; }
}
echo $drift ? "WS_DRIFT ($drift)\n" : "WS_CLEAN\n";
PHPEOF

    cat > /tmp/ws-drift-store.php << 'PHPEOF'
<?php
// Record current migration hashes; failures are non-fatal.
try {
    $pdo = new PDO(getenv('DB_DSN'), getenv('DB_USERNAME'), getenv('DB_PASSWORD'),
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_TIMEOUT => 5]);
    $mig = [];
    foreach (glob('migrations/*.php') as $f) {
        $mig[basename($f, '.php')] = hash_file('sha256', $f);
    }
    $pdo->exec('CREATE TABLE IF NOT EXISTS ws_migration_hashes
        (filename VARCHAR(191) PRIMARY KEY, hash CHAR(64) NOT NULL)');
    $pdo->exec('DELETE FROM ws_migration_hashes');
    $ins = $pdo->prepare('INSERT INTO ws_migration_hashes (filename, hash) VALUES (?, ?)');
    foreach ($pdo->query("SELECT version FROM migration WHERE version <> 'm000000_000000_base'") as $r) {
        if (isset($mig[$r['version']])) { $ins->execute([$r['version'], $mig[$r['version']]]); }
    }
} catch (Throwable $e) { fwrite(STDERR, 'hash store skipped: ' . $e->getMessage() . "\n"); }
PHPEOF

    cd /var/www/html
    MAX_TRIES=30
    TRIES=0
    while [ $TRIES -lt $MAX_TRIES ]; do
        STATE=$(php /tmp/ws-drift-check.php 2>/dev/null | grep -oE 'WS_(FIRST_BOOT|ADOPT|DRIFT|CLEAN)' | head -1)
        if [ -n "$STATE" ]; then
            echo "  Database connected"
            if [ "$STATE" = "WS_DRIFT" ]; then
                echo "  Schema drift detected (already-deployed migration changed)"
                echo "  Rebuilding database..."
                php yii migrate/fresh --interactive=0 2>/dev/null && echo "  Rebuild completed" || echo "  [WARN] migrate/fresh failed"
            else
                php yii migrate --interactive=0 2>/dev/null && echo "  Migrations completed" || echo "  [WARN] Migration failed"
            fi
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
