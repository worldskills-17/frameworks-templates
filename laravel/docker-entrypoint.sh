#!/bin/bash
set -e

echo "Creating storage symlink..."
php artisan storage:link --force

echo "Running database migrations..."
php artisan migrate --force

echo "Starting Apache..."
exec /usr/sbin/apache2ctl -D FOREGROUND
