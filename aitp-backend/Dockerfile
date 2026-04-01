# Stage 1: Install PHP dependencies
FROM composer:2.7 AS vendor

WORKDIR /app

COPY composer.json composer.lock ./

RUN composer install \
    --no-dev \
    --no-interaction \
    --no-scripts \
    --prefer-dist \
    --optimize-autoloader

# Stage 2: Production image with FrankenPHP
FROM dunglas/frankenphp:1.1-php8.2-alpine

# Install system dependencies and PHP extensions
RUN apk add --no-cache \
    bash \
    curl \
    libzip-dev \
    postgresql-dev \
    unzip \
    zip \
    icu-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
        gd \
        intl \
        opcache \
        pcntl \
        pdo \
        pdo_pgsql \
        pgsql \
        zip

WORKDIR /var/www/html

# Copy application code and vendor from builder
COPY . .
COPY --from=vendor /app/vendor ./vendor

# Set correct permissions for Laravel
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Environment variables for production
ENV APP_ENV=production
ENV APP_DEBUG=false
ENV PORT=8080
ENV SERVER_NAME=:8080

# Expose the configured port
EXPOSE ${PORT:-8080}

# Use the entrypoint script to run migrations and optimizations on startup
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Entrypoint handles setup, CMD starts FrankenPHP on the app's public dir
ENTRYPOINT ["entrypoint.sh"]
CMD ["frankenphp", "php-server", "-r", "public/", "--listen=:8080"]
