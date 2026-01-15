#!/bin/bash
# CodeIgniter 4 Docker Entrypoint
# Handles database connection and migrations

echo "=== CodeIgniter 4 Container Starting ==="

# Wait for database to be available (up to 30 seconds)
echo "Waiting for database connection..."
MAX_TRIES=30
TRIES=0
DB_READY=false

# Read database config from .env file
DB_HOST=$(grep "^database.default.hostname" /var/www/html/.env | cut -d'=' -f2 | tr -d ' ')
DB_NAME=$(grep "^database.default.database" /var/www/html/.env | cut -d'=' -f2 | tr -d ' ')
DB_USER=$(grep "^database.default.username" /var/www/html/.env | cut -d'=' -f2 | tr -d ' ')
DB_PASS=$(grep "^database.default.password" /var/www/html/.env | cut -d'=' -f2 | tr -d ' ')

while [ $TRIES -lt $MAX_TRIES ]; do
    # Try to connect to MySQL
    if php -r "try { new PDO('mysql:host=$DB_HOST;dbname=$DB_NAME', '$DB_USER', '$DB_PASS'); echo 'OK'; } catch(Exception \$e) { exit(1); }" 2>/dev/null | grep -q "OK"; then
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
    if php spark migrate --all 2>&1; then
        echo "  Migrations completed successfully"
    else
        echo "  [WARN] Migration failed - app may work with limited functionality"
        echo "  Check database permissions and migration files"
    fi
else
    echo "[WARN] Database not available after ${MAX_TRIES}s"
    echo "  App will start but database features won't work"
    echo "  Check database settings in .env file"
fi

echo "Starting Apache..."
exec /usr/sbin/apache2ctl -D FOREGROUND
