#--------------------------------------------------------------------------------
# Stage 1: "builder" - Compile PHP extensions
#--------------------------------------------------------------------------------
FROM php:7.4-fpm AS builder

# Install build dependencies
RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y \
    g++ \
    libedit-dev \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpq-dev \
    libssl-dev \
    libzip-dev \
    libpng-dev \
    && rm -rf /var/lib/apt/lists/*

# Configure PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure intl \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql

# Install PHP extensions (parallel compilation)
RUN docker-php-ext-install -j$(nproc) \
    gd \
    intl \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    mysqli \
    pgsql \
    bcmath \
    sockets \
    opcache \
    exif \
    zip

#--------------------------------------------------------------------------------
# Stage 2: "runtime" - Final lightweight image
#--------------------------------------------------------------------------------
FROM php:7.4-fpm AS runtime

# OCI Labels for GitHub Container Registry (enables public visibility linking)
LABEL org.opencontainers.image.source="https://github.com/skolerom/php-7.4-fpm"
LABEL org.opencontainers.image.description="PHP 7.4-FPM base image with common extensions (gd, intl, pdo, pgsql, mysql, zip, opcache)"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.title="php-7.4-fpm"
LABEL org.opencontainers.image.vendor="Skolerom AS"

# Set Timezone
ENV TZ=Europe/Oslo

# PHP OPcache Configuration
ENV PHP_OPCACHE_VALIDATE_TIMESTAMPS="0" \
    PHP_OPCACHE_MAX_ACCELERATED_FILES="12000" \
    PHP_OPCACHE_MEMORY_CONSUMPTION="192" \
    PHP_OPCACHE_MAX_WASTED_PERCENTAGE="10" \
    CLIENT_MAX_BODY_SIZE="20M"

# Composer Configuration
ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/tmp

# Set Timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install runtime dependencies only (no build tools)
RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y \
    apt-transport-https \
    ca-certificates \
    openssh-client \
    curl \
    dos2unix \
    git \
    gnupg2 \
    dirmngr \
    jq \
    libfcgi0ldbl \
    libfreetype6 \
    libicu67 \
    libjpeg62-turbo \
    libmcrypt4 \
    libpq5 \
    libssl1.1 \
    libzip4 \
    libpng16-16 \
    unzip \
    zip \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy compiled PHP extensions from builder stage
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

# Copy Composer from official image
COPY --from=composer:2.6 /usr/bin/composer /usr/bin/composer

# Create Composer PHP CLI Configuration
RUN printf "# composer php cli ini settings\n\
    date.timezone=UTC\n\
    memory_limit=-1\n\
    " > $PHP_INI_DIR/php-cli.ini

# Verify installations
RUN php --version && \
    php -m | grep -E '^(gd|intl|pdo|mysqli|pgsql|bcmath|sockets|exif|zip)$' && \
    composer --version --no-interaction

# Copy configuration files
COPY config/php/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY scripts/wait-for-it.sh /usr/local/bin/wait-for-it.sh

# Set permissions for scripts
RUN chmod +x /usr/local/bin/wait-for-it.sh
