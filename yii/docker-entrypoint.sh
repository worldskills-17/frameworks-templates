#!/bin/bash
# Yii2 Docker Entrypoint
# Handles database connection and migrations

echo "=== Yii2 Container Starting ==="

# Wait for database to be available (up to 30 seconds)
echo "Waiting for database connection..."
MAX_TRIES=30
TRIES=0
DB_READY=false

# Extract host and dbname from DB_DSN (format: mysql:host=xxx;dbname=yyy)
DB_HOST_PARSED=$(echo "$DB_DSN" | sed -n 's/.*host=\([^;]*\).*/\1/p')
DB_NAME_PARSED=$(echo "$DB_DSN" | sed -n 's/.*dbname=\([^;]*\).*/\1/p')

while [ $TRIES -lt $MAX_TRIES ]; do
    # Try to connect to MySQL
    if php -r "try { new PDO('$DB_DSN', '$DB_USERNAME', '$DB_PASSWORD'); echo 'OK'; } catch(Exception \$e) { exit(1); }" 2>/dev/null | grep -q "OK"; then
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
    cd /var/www/html
    if php yii migrate --interactive=0 2>&1; then
        echo "  Migrations completed successfully"
    else
        echo "  [WARN] Migration failed - app may work with limited functionality"
        echo "  Check database permissions and migration files"
    fi
else
    echo "[WARN] Database not available after ${MAX_TRIES}s"
    echo "  App will start but database features won't work"
    echo "  Check: DB_DSN, DB_USERNAME, DB_PASSWORD settings"
fi

echo "Starting Apache..."
exec /usr/sbin/apache2ctl -D FOREGROUND
