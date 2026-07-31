FROM php:8.4-apache

# NOTE: per-repo build args (DB_*, APP_URL) are declared right before first
# use, not here - early declaration would bust the heavy layer cache for
# every new module repo (classic builder folds ARG values into RUN cache keys).

# Install system dependencies (retry on transient CDN errors; quiet output)
RUN export DEBIAN_FRONTEND=noninteractive \
    && for i in 1 2 3; do \
        apt-get update -qq && apt-get install -qq -y \
            openssl zip unzip zlib1g-dev libpq-dev libicu-dev libzip-dev \
            curl libpng-dev git > /dev/null \
        && break; \
        [ "$i" = "3" ] && exit 1; \
        sleep $((i*5)); \
    done \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer --quiet \
    && docker-php-ext-install pdo pdo_pgsql pdo_mysql zip gd intl > /dev/null 2>&1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Configure Apache document root
ENV APACHE_DOCUMENT_ROOT /var/www/html/web
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Configure PHP settings
RUN echo "max_execution_time = 300" > /usr/local/etc/php/conf.d/custom.ini \
    && echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/custom.ini \
    && echo "upload_max_filesize = 50M" >> /usr/local/etc/php/conf.d/custom.ini \
    && echo "post_max_size = 50M" >> /usr/local/etc/php/conf.d/custom.ini

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
        composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist --quiet && break; \
        [ "$i" = "3" ] && exit 1; \
        sleep $((i*5)); \
    done

# Copy application code
COPY . .

# Per-repo database and app configuration (declared here, not at the top -
# see the note under FROM)
ARG DB_NAME
ARG DB_USERNAME
ARG DB_PASSWORD
ARG DB_HOST
ARG APP_URL

# Create .env with database config (file is gitignored so must be generated at build time)
RUN printf "YII_ENV=prod\nYII_DEBUG=false\nDB_DSN=mysql:host=%s;dbname=%s\nDB_USERNAME=%s\nDB_PASSWORD=%s\n" \
    "${DB_HOST}" "${DB_NAME}" "${DB_USERNAME}" "${DB_PASSWORD}" > .env

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/runtime \
    && chmod -R 775 /var/www/html/web/assets

# Set database environment variables (read by config/web.php)
ENV DB_DSN="mysql:host=${DB_HOST};dbname=${DB_NAME}"
ENV DB_USERNAME=${DB_USERNAME}
ENV DB_PASSWORD=${DB_PASSWORD}
ENV APP_URL=${APP_URL}

ENV YII_ENV=prod
ENV YII_DEBUG=false

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
