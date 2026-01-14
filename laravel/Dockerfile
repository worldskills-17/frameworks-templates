FROM php:8.4-apache

# Accept database and app configuration as build arguments
ARG DB_NAME
ARG DB_USERNAME
ARG DB_PASSWORD
ARG DB_HOST
ARG APP_URL
ARG COMPOSER_PROXY

# Install system dependencies and Node.js in a single layer (quiet mode)
# DEBIAN_FRONTEND=noninteractive suppresses debconf warnings about missing tty
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update -qq && apt-get install -qq -y \
    openssl zip unzip zlib1g-dev libpq-dev libicu-dev libzip-dev \
    curl libpng-dev nano git cron inetutils-ping > /dev/null \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer --quiet \
    && docker-php-ext-install pdo pdo_pgsql pdo_mysql zip gd exif > /dev/null 2>&1 \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - > /dev/null 2>&1 \
    && DEBIAN_FRONTEND=noninteractive apt-get install -qq -y nodejs > /dev/null \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configure Apache
COPY httpd-vhosts.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite > /dev/null

# Configure PHP settings in a single layer
RUN echo "max_execution_time = 1200" > /usr/local/etc/php/conf.d/execution.ini     && echo "memory_limit = 2048M" >> /usr/local/etc/php/conf.d/execution.ini     && echo "post_max_size = 100M" >> /usr/local/etc/php/conf.d/execution.ini     && echo "upload_max_filesize = 100M" >> /usr/local/etc/php/conf.d/execution.ini

WORKDIR /var/www/html/

# Copy composer files first for better layer caching
COPY composer.json composer.lock* ./

# Configure Composer to use caching proxy (if provided)
# secure-http disabled for internal HTTP mirror (Packeton on Docker network)
RUN if [ -n "$COMPOSER_PROXY" ]; then \
        composer config --global repo.packagist composer "$COMPOSER_PROXY" && \
        composer config --global secure-http false; \
    fi && \
    composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist --no-scripts --quiet

# Copy package files for Node.js dependencies
COPY package.json package-lock.json* ./

# Configure npm to use Verdaccio cache (if NPM_REGISTRY provided)
ARG NPM_REGISTRY
RUN if [ -n "$NPM_REGISTRY" ]; then \
        npm config set registry "$NPM_REGISTRY"; \
    fi && \
    npm ci --silent 2>/dev/null || npm ci --loglevel error

# Copy application code
COPY . .

# Replace placeholders in .env
RUN sed -i "s|{{DB_NAME}}|${DB_NAME}|g" .env && \
    sed -i "s|{{DB_USERNAME}}|${DB_USERNAME}|g" .env && \
    sed -i "s|{{DB_PASSWORD}}|${DB_PASSWORD}|g" .env && \
    sed -i "s|{{DB_HOST}}|${DB_HOST}|g" .env && \
    sed -i "s|{{APP_URL}}|${APP_URL}|g" .env

# Generate Laravel APP_KEY automatically
RUN php artisan key:generate --ansi --quiet

# Build assets (quiet mode - only show errors)
RUN npm run build --silent 2>&1 | grep -i error || true \
    && npm prune --production --silent 2>/dev/null \
    && npm cache clean --force --silent 2>/dev/null

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html
ENV APP_ENV=production

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
