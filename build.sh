#!/usr/bin/env bash
set -euo pipefail

# Simple NetBird ACAP builder
# Usage: ./build-simple.sh [VERSION]
# Example: ./build-simple.sh 0.30.0
# Example: ./build-simple.sh latest

VERSION="${1:-latest}"
SDK_VERSION="12.6.0"
UBUNTU_VERSION="24.04"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}==>${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*"; exit 1; }

# Check dependencies
command -v docker >/dev/null 2>&1 || error "docker is required but not installed"
command -v curl >/dev/null 2>&1 || error "curl is required but not installed"
command -v jq >/dev/null 2>&1 || error "jq is required but not installed"

info "Building NetBird ACAP packages (version: $VERSION)"

# Resolve actual version if "latest" is specified
ACTUAL_VERSION="$VERSION"
if [[ "$VERSION" == "latest" ]]; then
    info "Resolving latest NetBird version..."
    ACTUAL_VERSION=$(curl -fsSL https://api.github.com/repos/netbirdio/netbird/releases/latest | jq -r '.tag_name' | sed 's/^v//')
    info "Latest version is: $ACTUAL_VERSION"
fi

# Create output directory
mkdir -p dist/{armv6,arm64}

# Build function
build_arch() {
    local arch="$1"
    local sdk_arch="$2"
    local netbird_arch="$3"

    info "Building for $arch (SDK: $sdk_arch, NetBird: $netbird_arch)"

    # Build Docker image
    docker build \
        --build-arg ARCH="$sdk_arch" \
        --build-arg VERSION="$SDK_VERSION" \
        --build-arg UBUNTU_VERSION="$UBUNTU_VERSION" \
        --build-arg NETBIRD_VERSION="$VERSION" \
        --build-arg NETBIRD_ARCH="$netbird_arch" \
        --tag "netbird-acap:${ACTUAL_VERSION}-${arch}" \
        --file Dockerfile \
        . || error "Docker build failed for $arch"

    # Extract package
    info "Extracting package for $arch..."
    local container_id
    container_id=$(docker create "netbird-acap:${ACTUAL_VERSION}-${arch}")
    docker cp "$container_id:/opt/app/" "dist/$arch/" || error "Failed to extract package for $arch"
    docker rm "$container_id" >/dev/null

    # Find and rename the .eap file
    local eap_file
    eap_file=$(find "dist/$arch" -name "*.eap" -type f | head -n1)
    if [[ -n "$eap_file" ]]; then
        local new_name="netbird-acap_${ACTUAL_VERSION}_${arch}.eap"
        mv "$eap_file" "dist/$arch/$new_name"
        success "Created: dist/$arch/$new_name"
    else
        error "No .eap file found for $arch"
    fi
}

# Build for both architectures
build_arch "armv6" "armv7hf" "armv6"
build_arch "arm64" "aarch64" "arm64"

echo ""
success "All packages built successfully!"
info "Packages available in:"
ls -lh dist/*/*.eap 2>/dev/null || warn "No packages found"

# Show version info
echo ""
info "Built NetBird ACAP version: $ACTUAL_VERSION"
