FROM php:8.4-apache

# Install system dependencies and Node.js in a single layer
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
    nano \
    git \
    cron \
    inetutils-ping \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer \
    && docker-php-ext-install pdo pdo_pgsql pdo_mysql zip gd exif \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configure Apache
COPY httpd-vhosts.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# Configure PHP settings in a single layer
RUN echo "max_execution_time = 1200" > /usr/local/etc/php/conf.d/execution.ini \
    && echo "memory_limit = 2048M" >> /usr/local/etc/php/conf.d/execution.ini \
    && echo "post_max_size = 100M" >> /usr/local/etc/php/conf.d/execution.ini \
    && echo "upload_max_filesize = 100M" >> /usr/local/etc/php/conf.d/execution.ini

WORKDIR /var/www/html/

# Copy composer files first for better layer caching
COPY composer.json composer.lock* ./
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist --no-scripts

# Copy package files for Node.js dependencies
COPY package.json package-lock.json* ./
RUN npm ci

# Copy application code
COPY . .

# Build assets
RUN ls -la node_modules/.bin/ && \
    npm run build \
    && npm prune --production \
    && npm cache clean --force

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html
ENV APP_ENV=production

ENTRYPOINT ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
