#!/bin/sh
set -e

# Generate APP_KEY if missing
if [ -z "$APP_KEY" ]; then
    echo "Generating application key..."
    php artisan key:generate --show
fi

# Run migrations
echo "Running migrations..."
php artisan migrate --force

# Optimize for production
echo "Caching configuration and routes..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Execute the main command (passed as arguments)
exec "$@"
