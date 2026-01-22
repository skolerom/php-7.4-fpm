# =============================================================================
# Docker Image Configuration for GitHub Container Registry (GHCR)
# =============================================================================

# Include .env file if it exists (optional)
-include .env

# Image Configuration (defaults, can be overridden by .env or command line)
IMAGE_NAME ?= skolerom/php-7.4-fpm
IMAGE_TAG ?= latest
DOCKERFILE ?= Dockerfile

# Container Registry Configuration
CONTAINER_REGISTRY ?= ghcr.io

# GitHub repository for package linking (used for public visibility)
GITHUB_REPO ?= skolerom/docker-php-74-fpm

# Build Options
BUILD_ARGS ?=
NO_CACHE ?= false
PLATFORM ?= linux/amd64

# Computed Variables (do not override)
FULL_IMAGE_NAME = $(CONTAINER_REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)
LOCAL_IMAGE_NAME = $(IMAGE_NAME):$(IMAGE_TAG)

# =============================================================================
# Phony Targets
# =============================================================================
.PHONY: all build build-no-cache verify verify-php verify-extensions \
        verify-composer verify-gd test login login-ghcr push publish \
        build-multiarch publish-multiarch shell inspect size clean clean-all help info \
        make-public package-url

# Default target
all: build verify

# =============================================================================
##@ Build
# =============================================================================

build: ## Build the Docker image
	@echo "══════════════════════════════════════════════════════════════"
	@echo "Building $(FULL_IMAGE_NAME)"
	@echo "══════════════════════════════════════════════════════════════"
	docker build \
		$(if $(filter true,$(NO_CACHE)),--no-cache,) \
		$(BUILD_ARGS) \
		--label "org.opencontainers.image.source=https://github.com/$(GITHUB_REPO)" \
		--label "org.opencontainers.image.description=PHP 7.4-fpm base image with common extensions" \
		--label "org.opencontainers.image.licenses=MIT" \
		-t $(LOCAL_IMAGE_NAME) \
		-t $(FULL_IMAGE_NAME) \
		-f $(DOCKERFILE) \
		.
	@echo "✓ Build complete: $(FULL_IMAGE_NAME)"

build-no-cache: ## Build the Docker image without cache
	@$(MAKE) build NO_CACHE=true

# =============================================================================
##@ Verification
# =============================================================================

verify: ## Verify the built image (run all checks)
	@echo "══════════════════════════════════════════════════════════════"
	@echo "Verifying $(LOCAL_IMAGE_NAME)"
	@echo "══════════════════════════════════════════════════════════════"
	@$(MAKE) verify-php
	@$(MAKE) verify-extensions
	@$(MAKE) verify-composer
	@echo "✓ All verifications passed!"

verify-php: ## Verify PHP installation
	@echo "→ Checking PHP version..."
	@docker run --rm $(LOCAL_IMAGE_NAME) php -v

verify-extensions: ## Verify PHP extensions are installed
	@echo "→ Checking PHP extensions..."
	@docker run --rm $(LOCAL_IMAGE_NAME) php -m | grep -E '^(gd|intl|PDO|pdo_mysql|pdo_pgsql|mysqli|pgsql|bcmath|sockets|Zend OPcache|exif|zip)$$' | sort
	@echo "→ Verifying required extensions..."
	@docker run --rm $(LOCAL_IMAGE_NAME) sh -c '\
		for ext in gd intl PDO pdo_mysql pdo_pgsql mysqli pgsql bcmath sockets exif zip; do \
			php -m | grep -q "^$$ext$$" || { echo "✗ Missing extension: $$ext"; exit 1; }; \
		done && \
		php -m | grep -q "Zend OPcache" || { echo "✗ Missing extension: Zend OPcache"; exit 1; } && \
		echo "✓ All required extensions are installed"'

verify-composer: ## Verify Composer installation
	@echo "→ Checking Composer version..."
	@docker run --rm $(LOCAL_IMAGE_NAME) composer --version

verify-gd: ## Verify GD extension has freetype and jpeg support
	@echo "→ Checking GD configuration..."
	@docker run --rm $(LOCAL_IMAGE_NAME) php -r "print_r(gd_info());" | grep -E '(FreeType|JPEG)'

test: verify ## Alias for verify

# =============================================================================
##@ Publishing to GitHub Container Registry
# =============================================================================

login-ghcr: ## Login to GHCR using GITHUB_TOKEN
	@echo "══════════════════════════════════════════════════════════════"
	@echo "Logging in to GitHub Container Registry..."
	@echo "══════════════════════════════════════════════════════════════"
	@if [ -z "$(GITHUB_TOKEN)" ]; then \
		echo "✗ Error: GITHUB_TOKEN environment variable must be set"; \
		echo ""; \
		echo "To create a token:"; \
		echo "  1. Go to https://github.com/settings/tokens"; \
		echo "  2. Create a token with 'write:packages' scope"; \
		echo "  3. Export it: export GITHUB_TOKEN=your_token"; \
		echo ""; \
		exit 1; \
	fi
	@if [ -z "$(GITHUB_USER)" ]; then \
		echo "✗ Error: GITHUB_USER environment variable must be set"; \
		exit 1; \
	fi
	@echo "$(GITHUB_TOKEN)" | docker login $(CONTAINER_REGISTRY) -u $(GITHUB_USER) --password-stdin
	@echo "✓ Successfully logged in to $(CONTAINER_REGISTRY)"

login: login-ghcr ## Alias for login-ghcr

push: ## Push the image to GHCR
	@echo "══════════════════════════════════════════════════════════════"
	@echo "Pushing $(FULL_IMAGE_NAME)"
	@echo "══════════════════════════════════════════════════════════════"
	docker push $(FULL_IMAGE_NAME)
	@echo "✓ Push complete!"
	@echo ""
	@echo "Image available at: https://$(FULL_IMAGE_NAME)"

publish: build verify push ## Build, verify, and push to GHCR
	@echo "══════════════════════════════════════════════════════════════"
	@echo "✓ Published $(FULL_IMAGE_NAME) successfully!"
	@echo "══════════════════════════════════════════════════════════════"
	@echo ""
	@echo "To make this package PUBLIC, run: make make-public"

make-public: ## Show instructions to make the package public on GHCR
	@echo "══════════════════════════════════════════════════════════════"
	@echo "Making Package Public on GitHub Container Registry"
	@echo "══════════════════════════════════════════════════════════════"
	@echo ""
	@echo "GHCR packages are PRIVATE by default. To make it public:"
	@echo ""
	@echo "Option 1: Via GitHub Web UI"
	@echo "  1. Go to: https://github.com/orgs/$(firstword $(subst /, ,$(IMAGE_NAME)))/packages/container/$(lastword $(subst /, ,$(IMAGE_NAME)))/settings"
	@echo "     Or for personal accounts: https://github.com/users/$(firstword $(subst /, ,$(IMAGE_NAME)))/packages/container/$(lastword $(subst /, ,$(IMAGE_NAME)))/settings"
	@echo "  2. Scroll to 'Danger Zone'"
	@echo "  3. Click 'Change visibility'"
	@echo "  4. Select 'Public' and confirm"
	@echo ""
	@echo "Option 2: Via GitHub CLI (if installed)"
	@echo "  gh api -X PATCH /user/packages/container/$(lastword $(subst /, ,$(IMAGE_NAME))) -f visibility=public"
	@echo ""
	@echo "Option 3: Link to repository (recommended for org packages)"
	@echo "  1. Go to package settings (URL above)"
	@echo "  2. Under 'Repository source', connect to: $(GITHUB_REPO)"
	@echo "  3. The package will inherit repository visibility"
	@echo ""
	@echo "Note: The OCI labels in the image already link to the source repository."
	@echo ""

package-url: ## Show the package URL on GHCR
	@echo "Package URL: https://ghcr.io/$(IMAGE_NAME)"
	@echo "Settings:    https://github.com/orgs/$(firstword $(subst /, ,$(IMAGE_NAME)))/packages/container/$(lastword $(subst /, ,$(IMAGE_NAME)))/settings"

# =============================================================================
##@ Multi-Architecture Builds
# =============================================================================

build-multiarch: ## Build and push multi-architecture image (amd64, arm64)
	@echo "══════════════════════════════════════════════════════════════"
	@echo "Building multi-arch $(FULL_IMAGE_NAME)"
	@echo "══════════════════════════════════════════════════════════════"
	docker buildx build \
		$(if $(filter true,$(NO_CACHE)),--no-cache,) \
		$(BUILD_ARGS) \
		--platform linux/amd64,linux/arm64 \
		-t $(FULL_IMAGE_NAME) \
		-f $(DOCKERFILE) \
		--push \
		.
	@echo "✓ Multi-arch build and push complete!"

publish-multiarch: build-multiarch ## Alias for build-multiarch (builds and pushes)

# =============================================================================
##@ Utilities
# =============================================================================

shell: ## Run an interactive shell in the container
	docker run --rm -it $(LOCAL_IMAGE_NAME) /bin/bash

inspect: ## Inspect the image metadata
	docker inspect $(LOCAL_IMAGE_NAME)

size: ## Show image size
	@docker images $(LOCAL_IMAGE_NAME) --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

history: ## Show image layer history
	docker history $(LOCAL_IMAGE_NAME)

pull: ## Pull the image from GHCR
	docker pull $(FULL_IMAGE_NAME)

clean: ## Remove the built images
	@echo "Removing images..."
	-docker rmi $(LOCAL_IMAGE_NAME) $(FULL_IMAGE_NAME) 2>/dev/null || true
	@echo "✓ Cleanup complete!"

clean-all: clean ## Remove images and prune build cache
	@echo "Pruning build cache..."
	docker builder prune -f
	@echo "✓ Full cleanup complete!"

info: ## Show current configuration
	@echo ""
	@echo "Current Configuration"
	@echo "====================="
	@echo "IMAGE_NAME:         $(IMAGE_NAME)"
	@echo "IMAGE_TAG:          $(IMAGE_TAG)"
	@echo "CONTAINER_REGISTRY: $(CONTAINER_REGISTRY)"
	@echo "DOCKERFILE:         $(DOCKERFILE)"
	@echo "FULL_IMAGE_NAME:    $(FULL_IMAGE_NAME)"
	@echo "GITHUB_REPO:        $(GITHUB_REPO)"
	@echo "NO_CACHE:           $(NO_CACHE)"
	@echo "PLATFORM:           $(PLATFORM)"
	@echo ""

# =============================================================================
##@ Help
# =============================================================================

help: ## Display this help
	@echo ""
	@echo "GitHub Container Registry Makefile"
	@echo "==================================="
	@echo ""
	@echo "Image: $(FULL_IMAGE_NAME)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ""
	@echo "Configuration:"
	@echo "  Create a .env file to override defaults, or pass variables on command line."
	@echo "  Run 'make info' to see current configuration."
	@echo ""
	@echo "Examples:"
	@echo "  make build                          # Build with defaults from .env"
	@echo "  make build IMAGE_TAG=7.4-fpm        # Override tag"
	@echo "  make publish                        # Build, verify, and push"
	@echo "  make info                           # Show current config"
	@echo ""
