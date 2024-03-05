FROM php:8.3-fpm
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer
# Install PostgreSQL client and its PHP extensions
RUN apt-get update \
   # pgsql headers
    && apt-get install -y libpq-dev \
    && docker-php-ext-install pgsql pdo_pgsql pdo \