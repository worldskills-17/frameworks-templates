#!/bin/bash
# CodeIgniter 4 Docker Entrypoint
# Starts Apache immediately, runs migrations in background

echo "=== CodeIgniter 4 Container Starting ==="

# Run migrations in background so Apache starts immediately
(
    sleep 3
    DB_HOST=$(grep "^database.default.hostname" /var/www/html/.env | cut -d'=' -f2 | tr -d ' ')
    DB_NAME=$(grep "^database.default.database" /var/www/html/.env | cut -d'=' -f2 | tr -d ' ')
    DB_USER=$(grep "^database.default.username" /var/www/html/.env | cut -d'=' -f2 | tr -d ' ')
    DB_PASS=$(grep "^database.default.password" /var/www/html/.env | cut -d'=' -f2 | tr -d ' ')

    MAX_TRIES=30
    TRIES=0
    while [ $TRIES -lt $MAX_TRIES ]; do
        if php -r "try { new PDO('mysql:host=$DB_HOST;dbname=$DB_NAME', '$DB_USER', '$DB_PASS'); echo 'OK'; } catch(Exception \$e) { exit(1); }" 2>/dev/null | grep -q "OK"; then
            echo "  Database connected"
            cd /var/www/html && php spark migrate --all 2>/dev/null && echo "  Migrations completed" || echo "  [WARN] Migration failed"
            break
        fi
        TRIES=$((TRIES + 1))
        [ $((TRIES % 10)) -eq 0 ] && echo "  Waiting for database... ($TRIES/$MAX_TRIES)"
        sleep 1
    done
) &

echo "Starting Apache..."
exec /usr/sbin/apache2ctl -D FOREGROUND
