FROM php:8.4-apache

# NOTE: per-repo build args (DB_*, APP_URL) are deliberately declared far
# below, right before first use. The classic builder folds declared ARG
# values into the cache key of every later RUN - declaring them here would
# make each module repo rebuild the heavy apt/extension layers from scratch.

# Install system dependencies and Node.js (retry on transient CDN errors)
RUN export DEBIAN_FRONTEND=noninteractive \
    && for i in 1 2 3; do \
        apt-get update -qq && apt-get install -qq -y \
            openssl zip unzip zlib1g-dev libpq-dev libicu-dev libzip-dev \
            curl libpng-dev nano git cron inetutils-ping > /dev/null \
        && break; \
        [ "$i" = "3" ] && exit 1; \
        sleep $((i*5)); \
    done \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer --quiet \
    && docker-php-ext-install pdo pdo_pgsql pdo_mysql zip gd exif > /dev/null 2>&1 \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - > /dev/null 2>&1 \
    && for i in 1 2 3; do \
        DEBIAN_FRONTEND=noninteractive apt-get install -qq -y nodejs > /dev/null && break; \
        [ "$i" = "3" ] && exit 1; \
        sleep $((i*5)); \
    done \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configure Apache
COPY httpd-vhosts.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite > /dev/null

# Configure PHP settings in a single layer
RUN echo "max_execution_time = 1200" > /usr/local/etc/php/conf.d/execution.ini     && echo "memory_limit = 2048M" >> /usr/local/etc/php/conf.d/execution.ini     && echo "post_max_size = 100M" >> /usr/local/etc/php/conf.d/execution.ini     && echo "upload_max_filesize = 100M" >> /usr/local/etc/php/conf.d/execution.ini

# Force HTTPS scheme — Traefik terminates SSL and forwards HTTP to Apache,
# so Laravel sees HTTP and generates http:// asset URLs (mixed content).
# auto_prepend_file runs before ANY PHP code, setting $_SERVER['HTTPS']='on'.
RUN printf '<?php\n$_SERVER["HTTPS"] = "on";\n$_SERVER["SERVER_PORT"] = 443;\n$_SERVER["HTTP_X_FORWARDED_PROTO"] = "https";\n$_SERVER["HTTP_X_FORWARDED_SSL"] = "on";\n' > /usr/local/etc/php/force-https.php \
    && echo "auto_prepend_file = /usr/local/etc/php/force-https.php" > /usr/local/etc/php/conf.d/99-force-https.ini

WORKDIR /var/www/html/

# Copy composer files first for better layer caching
COPY composer.json composer.lock* ./

# Trust self-signed SSL cert (for internal HTTPS services like Packeton/Gitea)
# ssl-cert.crt is copied into build context by CI workflow
COPY ssl-cert.crt* /tmp/
RUN set -e; \
    for i in 1 2 3; do \
        apt-get update -qq && apt-get install -qq -y ca-certificates > /dev/null && break; \
        [ "$i" = "3" ] && exit 1; \
        sleep $((i*3)); \
    done; \
    rm -rf /var/lib/apt/lists/* \
    && if [ -f /tmp/ssl-cert.crt ]; then \
        cp /tmp/ssl-cert.crt /usr/local/share/ca-certificates/ssl-cert.crt && \
        update-ca-certificates; \
    fi

# Configure Composer to use caching proxy (if provided)
# disable-tls for isolated network with self-signed certs
ARG COMPOSER_PROXY
RUN if [ -n "$COMPOSER_PROXY" ]; then \
        composer config --global repo.packagist composer "$COMPOSER_PROXY" && \
        composer config --global disable-tls true; \
    fi && \
    for i in 1 2 3; do \
        composer install --optimize-autoloader --no-interaction --prefer-dist --no-scripts --quiet && break; \
        [ "$i" = "3" ] && exit 1; \
        sleep $((i*5)); \
    done
# NOTE: dev deps kept on purpose. Laravel's DatabaseSeeder uses fakerphp/faker
# which lives in require-dev; running with --no-dev breaks `php artisan db:seed`
# during competition setup. Image grows ~10MB; the tradeoff is correctness.

# Copy package files for Node.js dependencies (optional - a Blade-only app
# with no compiled assets may have no package.json at all). composer.json is
# re-listed as an anchor: the classic builder rejects a COPY where every
# pattern matches zero files.
COPY composer.json package.json* package-lock.json* ./

# Configure npm to use Verdaccio cache (if NPM_REGISTRY provided)
ARG NPM_REGISTRY
RUN if [ -f package.json ]; then \
        if [ -n "$NPM_REGISTRY" ]; then \
            npm config set registry "$NPM_REGISTRY" && \
            npm config set strict-ssl false; \
        fi && \
        for i in 1 2 3; do npm install --loglevel error && break; [ "$i" = "3" ] && exit 1; sleep $((i*3)); done; \
    else \
        echo "No package.json - skipping npm install"; \
    fi

# Copy application code
COPY . .

# Per-repo database and app configuration (declared here, not at the top -
# see the note under FROM)
ARG DB_NAME
ARG DB_USERNAME
ARG DB_PASSWORD
ARG DB_HOST
ARG APP_URL

# Force correct values in .env (overrides any competitor changes)
RUN sed -i "s|^DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|" .env && \
    sed -i "s|^DB_USERNAME=.*|DB_USERNAME=${DB_USERNAME}|" .env && \
    sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=${DB_PASSWORD}|" .env && \
    sed -i "s|^DB_HOST=.*|DB_HOST=${DB_HOST}|" .env && \
    sed -i "s|^APP_URL=.*|APP_URL=${APP_URL}|" .env && \
    sed -i "s|^DB_CONNECTION=.*|DB_CONNECTION=mysql|" .env

# Generate Laravel APP_KEY automatically
RUN php artisan key:generate --ansi --quiet

# Build assets (skipped when there is no package.json or no build script -
# the app then serves its CSS/JS straight from public/)
RUN if [ -f package.json ] && node -e "p=require('./package.json');process.exit(p.scripts&&p.scripts.build?0:1)"; then \
        npm run build \
        && npm prune --production --silent 2>/dev/null \
        && npm cache clean --force --silent 2>/dev/null; \
    else \
        echo "No package.json build script - skipping asset build"; \
    fi

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html
ENV APP_ENV=production

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
