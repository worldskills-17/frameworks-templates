#!/bin/bash
set -e
echo "=== Laravel Container Starting ==="

# Brief sleep to let DB stabilize on fresh deploys (no PHP-based ping needed)
sleep 3

php artisan storage:link --force 2>/dev/null || true
php artisan config:clear 2>/dev/null || true
php artisan route:clear 2>/dev/null || true
php artisan view:clear 2>/dev/null || true

echo "Running migrations..."
# Retry up to 30s in case DB is briefly unreachable
for i in 1 2 3 4 5 6 7 8 9 10; do
    if php artisan migrate --force 2>&1 | tee /tmp/migrate.log | grep -qE "Nothing to migrate|migrated"; then
        echo "  OK"
        break
    fi
    echo "  retry $i/10..."
    sleep 3
done

# Schema sanity check
EXPECTED="users sessions migrations"
MISSING=""
for t in $EXPECTED; do
    php artisan tinker --execute "DB::table(\"$t\")->limit(1)->get();" >/dev/null 2>&1 || MISSING="$MISSING $t"
done
if [ -n "$MISSING" ]; then
    echo "[WARN] Missing tables:$MISSING - running migrate:fresh"
    php artisan migrate:fresh --force 2>&1 | tail -5
fi

echo "Starting Apache..."
exec /usr/sbin/apache2ctl -D FOREGROUND
