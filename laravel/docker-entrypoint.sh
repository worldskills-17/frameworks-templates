#!/bin/bash
# Laravel Docker Entrypoint
# Starts Apache immediately, runs migrations in background

echo "=== Laravel Container Starting ==="

echo "Creating storage symlink..."
php artisan storage:link --force 2>/dev/null || true

# Clear caches to avoid stale config from build phase
php artisan config:clear 2>/dev/null || true
php artisan route:clear 2>/dev/null || true
php artisan view:clear 2>/dev/null || true

# Run migrations in background so Apache starts immediately
(
    MAX_TRIES=60
    TRIES=0

    while [ $TRIES -lt $MAX_TRIES ]; do
        if php artisan migrate --force 2>&1 | tee /tmp/migrate.log | grep -qE "(Migrating|Nothing to migrate|migrated)"; then
            echo "  Migrations completed successfully"
            break
        fi
        TRIES=$((TRIES + 1))
        if [ $((TRIES % 10)) -eq 0 ]; then
            echo "  Waiting for database... (attempt $TRIES/$MAX_TRIES)"
        fi
        sleep 1
    done

    if [ $TRIES -eq $MAX_TRIES ]; then
        echo "[WARN] Could not run migrations after ${MAX_TRIES}s"
        echo "  Last output: $(tail -3 /tmp/migrate.log 2>/dev/null)"
    fi
) &

echo "Starting Apache..."
exec /usr/sbin/apache2ctl -D FOREGROUND
