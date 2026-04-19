#!/bin/sh
set -e

wait_for_database() {
    if [ "$DB_CONNECTION" = "sqlite" ]; then
        return 0
    fi

    max_attempts="${DB_CONNECT_RETRIES:-30}"
    sleep_seconds="${DB_CONNECT_RETRY_SECONDS:-2}"
    attempt=1

    echo "Waiting for database..."
    until php -r '
$driver = getenv("DB_CONNECTION") ?: "sqlite";
if ($driver === "sqlite") {
    exit(0);
}

$host = getenv("DB_HOST") ?: "127.0.0.1";
$port = getenv("DB_PORT") ?: ($driver === "pgsql" ? "5432" : "3306");
$database = getenv("DB_DATABASE") ?: "laravel";
$username = getenv("DB_USERNAME") ?: "root";
$password = getenv("DB_PASSWORD") ?: "";
$sslmode = getenv("DB_SSLMODE") ?: "prefer";

if ($driver === "pgsql") {
    $dsn = "pgsql:host={$host};port={$port};dbname={$database};sslmode={$sslmode}";
} elseif ($driver === "mysql" || $driver === "mariadb") {
    $dsn = "mysql:host={$host};port={$port};dbname={$database}";
} else {
    exit(0);
}

try {
    new PDO($dsn, $username, $password, [PDO::ATTR_TIMEOUT => 5]);
} catch (Throwable $e) {
    fwrite(STDERR, $e->getMessage() . PHP_EOL);
    exit(1);
}
    '; do
        if [ "$attempt" -ge "$max_attempts" ]; then
            echo "Database did not become reachable after $max_attempts attempts."
            return 1
        fi

        echo "Database is not reachable yet. Retrying in ${sleep_seconds}s... ($attempt/$max_attempts)"
        attempt=$((attempt + 1))
        sleep "$sleep_seconds"
    done
}

# Generate APP_KEY if missing
if [ -z "$APP_KEY" ]; then
    echo "Generating application key..."
    APP_KEY="$(php artisan key:generate --show)"
    export APP_KEY
fi

wait_for_database

# Run migrations
echo "Running migrations..."
php artisan migrate --force

# Seed the database (creates the default admin user)
echo "Running seeders..."
php artisan db:seed --class=AdminUserSeeder --force

# Optimize for production
echo "Caching configuration and routes..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Execute the main command (passed as arguments)
exec "$@"
