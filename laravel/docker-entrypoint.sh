#!/bin/bash
# Laravel Docker Entrypoint
# Handles database connection and migrations

echo "=== Laravel Container Starting ==="

echo "Creating storage symlink..."
php artisan storage:link --force 2>/dev/null || true

# Wait for database and run migrations (up to 60 seconds)
echo "Waiting for database and running migrations..."
MAX_TRIES=60
TRIES=0
MIGRATED=false

while [ $TRIES -lt $MAX_TRIES ]; do
    # Try to run migrations directly - Laravel will fail if DB not ready
    if php artisan migrate --force 2>&1 | tee /tmp/migrate.log | grep -qE "(Migrating|Nothing to migrate|migrated)"; then
        MIGRATED=true
        echo "  Migrations completed successfully"
        break
    fi
    TRIES=$((TRIES + 1))
    if [ $((TRIES % 10)) -eq 0 ]; then
        echo "  Waiting for database... (attempt $TRIES/$MAX_TRIES)"
    fi
    sleep 1
done

if [ "$MIGRATED" = false ]; then
    echo "[WARN] Could not run migrations after ${MAX_TRIES}s"
    echo "  Last output: $(tail -3 /tmp/migrate.log 2>/dev/null)"
    echo "  App will start but may have limited functionality"
fi

echo "Starting Apache..."
exec /usr/sbin/apache2ctl -D FOREGROUND
