FROM php:8.3-apache

# NOTE: per-repo build args (DB_*, APP_URL) are declared right before first
# use, not here - early declaration would bust the layer cache for every new
# module repo (classic builder folds ARG values into RUN cache keys).

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_mysql mysqli

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Copy application files
COPY . /var/www/html/

# Set permissions
RUN chown -R www-data:www-data /var/www/html

# Per-repo database and app configuration (declared here, not at the top -
# see the note under FROM)
ARG DB_NAME
ARG DB_USERNAME
ARG DB_PASSWORD
ARG DB_HOST
ARG APP_URL

# Set database environment variables (read by PHP via getenv())
ENV DB_HOST=${DB_HOST}
ENV DB_NAME=${DB_NAME}
ENV DB_USER=${DB_USERNAME}
ENV DB_PASSWORD=${DB_PASSWORD}
ENV APP_URL=${APP_URL}

# Expose port 80
EXPOSE 80
