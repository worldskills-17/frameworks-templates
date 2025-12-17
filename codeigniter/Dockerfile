FROM php:8.4-apache

# Accept database and app configuration as build arguments
ARG DB_NAME
ARG DB_USERNAME
ARG DB_PASSWORD
ARG DB_HOST
ARG APP_URL
ARG COMPOSER_PROXY

# Install system dependencies
RUN apt-get update -y && apt-get install -y \
    openssl \
    zip \
    unzip \
    zlib1g-dev \
    libpq-dev \
    libicu-dev \
    libzip-dev \
    curl \
    libpng-dev \
    git \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer \
    && docker-php-ext-install pdo pdo_pgsql pdo_mysql zip gd intl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Configure Apache document root
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
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

# Configure Composer to use caching proxy (if provided)
RUN if [ -n "$COMPOSER_PROXY" ]; then \
        composer config --global repo.packagist composer "$COMPOSER_PROXY"; \
    fi && \
    composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist --quiet

# Copy application code
COPY . .

# Replace placeholders in .env
RUN sed -i "s|{{DB_NAME}}|${DB_NAME}|g" .env && \
    sed -i "s|{{DB_USERNAME}}|${DB_USERNAME}|g" .env && \
    sed -i "s|{{DB_PASSWORD}}|${DB_PASSWORD}|g" .env && \
    sed -i "s|{{DB_HOST}}|${DB_HOST}|g" .env && \
    sed -i "s|{{APP_URL}}|${APP_URL}|g" .env

# Set proper permissions for writable directory
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/writable

ENV CI_ENVIRONMENT=production

EXPOSE 80
