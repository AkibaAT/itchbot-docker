FROM php:8.2-fpm
# Install PostgreSQL client and its PHP extensions
RUN apt-get update \
   # pgsql headers
    && apt-get install -y libpq-dev \
    && docker-php-ext-install pgsql pdo_pgsql pdo \
