#!/bin/bash
# Laravel Docker Entrypoint
# Handles database connection and migrations

echo "=== Laravel Container Starting ==="

echo "Creating storage symlink..."
php artisan storage:link --force 2>/dev/null || true

# Wait for database to be available (up to 30 seconds)
echo "Waiting for database connection..."
MAX_TRIES=30
TRIES=0
DB_READY=false

while [ $TRIES -lt $MAX_TRIES ]; do
    if php artisan db:show --json 2>/dev/null | grep -q '"name"'; then
        DB_READY=true
        echo "  Database connected successfully"
        break
    fi
    TRIES=$((TRIES + 1))
    echo "  Waiting for database... (attempt $TRIES/$MAX_TRIES)"
    sleep 1
done

if [ "$DB_READY" = true ]; then
    echo "Running database migrations..."
    if php artisan migrate --force 2>&1; then
        echo "  Migrations completed successfully"
    else
        echo "  [WARN] Migration failed - app may work with limited functionality"
        echo "  Check database permissions and connection settings"
    fi
else
    echo "[WARN] Database not available after ${MAX_TRIES}s"
    echo "  App will start but database features won't work"
    echo "  Check: DB_HOST, DB_NAME, DB_USERNAME, DB_PASSWORD settings"
fi

echo "Starting Apache..."
exec /usr/sbin/apache2ctl -D FOREGROUND
