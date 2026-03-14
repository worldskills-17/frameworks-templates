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

# Force HTTPS scheme — Traefik terminates SSL and forwards HTTP to Apache,
# so Laravel sees HTTP and generates http:// asset URLs (mixed content).
# auto_prepend_file runs before ANY PHP code, setting $_SERVER['HTTPS']='on'.
RUN printf '<?php\n$_SERVER["HTTPS"] = "on";\n$_SERVER["SERVER_PORT"] = 443;\n$_SERVER["HTTP_X_FORWARDED_PROTO"] = "https";\n$_SERVER["HTTP_X_FORWARDED_SSL"] = "on";\n' > /usr/local/etc/php/force-https.php \
    && echo "auto_prepend_file = /usr/local/etc/php/force-https.php" > /usr/local/etc/php/conf.d/99-force-https.ini

WORKDIR /var/www/html/

# Copy composer files first for better layer caching
COPY composer.json composer.lock* ./

# Trust self-signed CA cert (for internal HTTPS services like Packeton/Gitea)
# ca-cert.crt is copied into build context by CI workflow
COPY ca-cert.crt* /tmp/
RUN apt-get update -qq && apt-get install -qq -y ca-certificates > /dev/null && rm -rf /var/lib/apt/lists/* \
    && if [ -f /tmp/ca-cert.crt ]; then \
        cp /tmp/ca-cert.crt /usr/local/share/ca-certificates/competition-ca.crt && \
        update-ca-certificates; \
    fi

# Configure Composer to use caching proxy (if provided)
# disable-tls for isolated network with self-signed certs
RUN if [ -n "$COMPOSER_PROXY" ]; then \
        composer config --global repo.packagist composer "$COMPOSER_PROXY" && \
        composer config --global disable-tls true; \
    fi && \
    composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist --no-scripts --quiet

# Copy package files for Node.js dependencies
COPY package.json package-lock.json* ./

# Configure npm to use Verdaccio cache (if NPM_REGISTRY provided)
ARG NPM_REGISTRY
RUN if [ -n "$NPM_REGISTRY" ]; then \
        npm config set registry "$NPM_REGISTRY" && \
        npm config set strict-ssl false; \
    fi && \
    npm install --loglevel error

# Copy application code
COPY . .

# Force correct values in .env (overrides any competitor changes)
RUN sed -i "s|^DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|" .env && \
    sed -i "s|^DB_USERNAME=.*|DB_USERNAME=${DB_USERNAME}|" .env && \
    sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=${DB_PASSWORD}|" .env && \
    sed -i "s|^DB_HOST=.*|DB_HOST=${DB_HOST}|" .env && \
    sed -i "s|^APP_URL=.*|APP_URL=${APP_URL}|" .env && \
    sed -i "s|^DB_CONNECTION=.*|DB_CONNECTION=mysql|" .env

# Generate Laravel APP_KEY automatically
RUN php artisan key:generate --ansi --quiet

# Build assets
RUN npm run build \
    && npm prune --production --silent 2>/dev/null \
    && npm cache clean --force --silent 2>/dev/null

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html
ENV APP_ENV=production

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
