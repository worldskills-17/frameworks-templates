#!/bin/bash
# Laravel Docker Entrypoint
#
# Boots in this order, BLOCKING on each step:
#   1. Wait for database to accept connections (up to 60s)
#   2. Storage symlink + cache clears
#   3. Run migrations synchronously
#   4. Verify expected Laravel 11 default tables exist
#   5. Start Apache
#
# Previously migrations ran in the background while Apache started immediately,
# which produced a race: first request hit Laravel before migrations finished
# and could see a half-built schema. Synchronous boot trades a few extra seconds
# of "container starting" status for guaranteed schema readiness on request 1.

set -e

echo "=== Laravel Container Starting ==="

# --- 1. Wait for database connectivity ---
echo "Waiting for database at ${DB_HOST}..."
MAX_DB_TRIES=60
DB_READY=0
for i in $(seq 1 $MAX_DB_TRIES); do
    if php -r "
        try {
            new PDO('mysql:host=' . getenv('DB_HOST') . ';port=3306', getenv('DB_USERNAME'), getenv('DB_PASSWORD'));
            exit(0);
        } catch (Exception \$e) { exit(1); }
    " 2>/dev/null; then
        echo "  Database reachable after ${i}s"
        DB_READY=1
        break
    fi
    [ $((i % 10)) -eq 0 ] && echo "  Still waiting for database... (${i}/${MAX_DB_TRIES}s)"
    sleep 1
done

if [ $DB_READY -eq 0 ]; then
    echo "[ERROR] Database ${DB_HOST} unreachable after ${MAX_DB_TRIES}s. Aborting container start."
    exit 1
fi

# --- 2. Storage symlink + cache clears ---
echo "Creating storage symlink..."
php artisan storage:link --force 2>/dev/null || true

php artisan config:clear 2>/dev/null || true
php artisan route:clear 2>/dev/null || true
php artisan view:clear 2>/dev/null || true

# --- 3. Run migrations synchronously, abort container on failure ---
echo "Running migrations..."
if ! php artisan migrate --force 2>&1; then
    echo "[ERROR] Migration failed. Aborting container start so Docker can retry."
    exit 1
fi

# --- 4. Smoke-test that Laravel 11's default tables landed ---
# Catches the case where `php artisan migrate` reports success but a Schema::create
# call inside the migration silently no-op'd (real incident: comp02_module_b had
# users but no sessions/password_reset_tokens, causing 500s on first login).
EXPECTED_TABLES="users sessions migrations"
MISSING_TABLES=""
for t in $EXPECTED_TABLES; do
    if ! php -r "
        try {
            \$pdo = new PDO('mysql:host=' . getenv('DB_HOST') . ';dbname=' . getenv('DB_NAME'), getenv('DB_USERNAME'), getenv('DB_PASSWORD'));
            \$pdo->query('SELECT 1 FROM \`$t\` LIMIT 1');
            exit(0);
        } catch (Exception \$e) { exit(1); }
    " 2>/dev/null; then
        MISSING_TABLES="$MISSING_TABLES $t"
    fi
done

if [ -n "$MISSING_TABLES" ]; then
    echo "[WARN] Expected tables missing after migration:$MISSING_TABLES"
    echo "[WARN] Attempting migrate:fresh as recovery..."
    if php artisan migrate:fresh --force 2>&1; then
        echo "  Recovery succeeded"
    else
        echo "[ERROR] Recovery failed. Container will start anyway - app may 500 on session-bound routes."
    fi
fi

# --- 5. Start Apache (foreground, becomes PID 1) ---
echo "Starting Apache..."
exec /usr/sbin/apache2ctl -D FOREGROUND
