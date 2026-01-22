# PHP 7.4-FPM Docker Image

[![Docker Image](https://img.shields.io/badge/ghcr.io-skolerom%2Fphp--7.4--fpm-blue)](https://ghcr.io/skolerom/php-7.4-fpm)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A production-ready PHP 7.4-FPM Docker image with common extensions pre-installed. Built using a multi-stage Dockerfile for optimized image size.

## Features

- **PHP 7.4-FPM** base image
- **Multi-stage build** for smaller image size
- **Pre-installed extensions**: gd, intl, pdo, pdo_mysql, pdo_pgsql, mysqli, pgsql, bcmath, sockets, opcache, exif, zip
- **Composer 2.6** included
- **OPcache** optimized configuration
- **Timezone** set to Europe/Oslo by default
- **wait-for-it** script for service dependency management

## Quick Start

### Pull from GitHub Container Registry

```bash
docker pull ghcr.io/skolerom/php-7.4-fpm:latest
```

### Use in Docker Compose

```yaml
services:
  php:
    image: ghcr.io/skolerom/php-7.4-fpm:latest
    volumes:
      - ./src:/var/www/html
    environment:
      - PHP_OPCACHE_VALIDATE_TIMESTAMPS=1
```

### Use as Base Image

```dockerfile
FROM ghcr.io/skolerom/php-7.4-fpm:latest

# Add your application
COPY . /var/www/html

# Install dependencies
RUN composer install --no-dev --optimize-autoloader
```

## Included PHP Extensions

| Extension    | Description                          |
|--------------|--------------------------------------|
| gd           | Image processing (with FreeType & JPEG) |
| intl         | Internationalization                 |
| pdo          | PHP Data Objects                     |
| pdo_mysql    | MySQL driver for PDO                 |
| pdo_pgsql    | PostgreSQL driver for PDO            |
| mysqli       | MySQL Improved Extension             |
| pgsql        | PostgreSQL Extension                 |
| bcmath       | Arbitrary Precision Mathematics      |
| sockets      | Socket communication                 |
| opcache      | Opcode caching                       |
| exif         | EXIF metadata reading                |
| zip          | ZIP archive handling                 |

## Environment Variables

### OPcache Configuration

| Variable                           | Default | Description                              |
|------------------------------------|---------|------------------------------------------|
| `PHP_OPCACHE_VALIDATE_TIMESTAMPS`  | `0`     | Check file timestamps (0 for production) |
| `PHP_OPCACHE_MAX_ACCELERATED_FILES`| `12000` | Max number of files to cache             |
| `PHP_OPCACHE_MEMORY_CONSUMPTION`   | `192`   | Memory for opcode cache (MB)             |
| `PHP_OPCACHE_MAX_WASTED_PERCENTAGE`| `10`    | Max wasted memory percentage             |

### Other Settings

| Variable              | Default       | Description                |
|-----------------------|---------------|----------------------------|
| `TZ`                  | `Europe/Oslo` | Container timezone         |
| `CLIENT_MAX_BODY_SIZE`| `20M`         | Max upload size            |

## Using wait-for-it

The image includes [wait-for-it](https://github.com/vishnubob/wait-for-it) for waiting on service dependencies:

```bash
# Wait for database before starting
wait-for-it.sh db:5432 -- php artisan migrate
```

### wait-for-it Options

```
Usage: wait-for-it.sh host:port [-s] [-t timeout] [-- command args]
    -h HOST | --host=HOST       Host or IP under test
    -p PORT | --port=PORT       TCP port under test
    -s | --strict               Only execute subcommand if the test succeeds
    -q | --quiet                Don't output any status messages
    -t TIMEOUT | --timeout=TIMEOUT
                                Timeout in seconds, zero for no timeout
    -- COMMAND ARGS             Execute command with args after the test finishes
```

## Building Locally

### Prerequisites

- Docker 20.10+
- GNU Make (optional, for using Makefile)

### Build Commands

```bash
# Build the image
make build

# Build without cache
make build-no-cache

# Verify the build
make verify

# Build and verify
make all
```

### Publishing to GHCR

```bash
# Set credentials
export GITHUB_USER=your-username
export GITHUB_TOKEN=your-token

# Login to GHCR
make login

# Build, verify, and push
make publish
```

### Multi-Architecture Build

```bash
# Build for amd64 and arm64
make build-multiarch
```

## Makefile Targets

| Target             | Description                                    |
|--------------------|------------------------------------------------|
| `build`            | Build the Docker image                         |
| `build-no-cache`   | Build without Docker cache                     |
| `verify`           | Run all verification checks                    |
| `verify-php`       | Verify PHP installation                        |
| `verify-extensions`| Verify PHP extensions are installed            |
| `verify-composer`  | Verify Composer installation                   |
| `verify-gd`        | Verify GD has freetype and jpeg support        |
| `login`            | Login to GitHub Container Registry             |
| `push`             | Push image to GHCR                             |
| `publish`          | Build, verify, and push                        |
| `build-multiarch`  | Build multi-architecture image                 |
| `shell`            | Run interactive shell in container             |
| `inspect`          | Inspect image metadata                         |
| `size`             | Show image size                                |
| `clean`            | Remove built images                            |
| `clean-all`        | Remove images and prune build cache            |
| `info`             | Show current configuration                     |
| `help`             | Display help                                   |

## Configuration

You can override default settings by creating a `.env` file:

```bash
IMAGE_NAME=skolerom/php-7.4-fpm
IMAGE_TAG=latest
CONTAINER_REGISTRY=ghcr.io
```

Or pass variables on the command line:

```bash
make build IMAGE_TAG=7.4-custom
```

## Image Labels

The image includes OCI-compliant labels for GitHub Container Registry:

- `org.opencontainers.image.source` - Links to source repository
- `org.opencontainers.image.description` - Image description
- `org.opencontainers.image.licenses` - License information
- `org.opencontainers.image.title` - Image title
- `org.opencontainers.image.vendor` - Vendor name

## License

This project is licensed under the MIT License.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request