FROM php:8.3-apache

# Accept database and app configuration as build arguments
ARG DB_NAME
ARG DB_USERNAME
ARG DB_PASSWORD
ARG DB_HOST
ARG APP_URL

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_mysql mysqli

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Copy application files
COPY . /var/www/html/

# Set permissions
RUN chown -R www-data:www-data /var/www/html

# Set database environment variables (read by PHP via getenv())
ENV DB_HOST=${DB_HOST}
ENV DB_NAME=${DB_NAME}
ENV DB_USER=${DB_USERNAME}
ENV DB_PASSWORD=${DB_PASSWORD}
ENV APP_URL=${APP_URL}

# Expose port 80
EXPOSE 80
