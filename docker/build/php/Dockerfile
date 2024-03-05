FROM dunglas/frankenphp:1.1-php8.3

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN apt-get update; \
    apt-get upgrade -yqq; \
    apt-get install -yqq --no-install-recommends --show-progress \
        apt-utils \
        curl \
        wget \
        nano \
        ncdu \
        ca-certificates \
        supervisor \
        libsodium-dev \
        unzip \
    # Install PHP extensions
    && install-php-extensions \
        bz2 \
        pcntl \
        mbstring \
        bcmath \
        sockets \
        pgsql \
        pdo_pgsql \
        opcache \
        exif \
        pdo_mysql \
        zip \
        intl \
        gd \
        redis \
        rdkafka \
        memcached \
        igbinary \
    && apt-get -y autoremove \
    && apt-get clean \
    && docker-php-source delete \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && rm /var/log/lastlog /var/log/faillog

ENTRYPOINT ["php", "artisan", "octane:frankenphp", "--host=0.0.0.0", "--port=80", "--admin-port=2019"]
