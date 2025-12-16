FROM php:8.4-apache

# Accept database and app configuration as build arguments
ARG DB_NAME
ARG DB_USERNAME
ARG DB_PASSWORD
ARG DB_HOST
ARG APP_URL

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
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist --quiet

# Copy application code
COPY . .

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

EXPOSE 80
