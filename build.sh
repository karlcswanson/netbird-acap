#!/bin/sh

NETBIRD_VERSION="0.52.12"

# NetBird release URLs (armv6 for armv7hf, arm64 for aarch64)
ARMV6_URL="https://github.com/netbirdio/netbird/releases/download/v${NETBIRD_VERSION}/netbird_${NETBIRD_VERSION}_linux_armv6.tar.gz"
ARM64_URL="https://github.com/netbirdio/netbird/releases/download/v${NETBIRD_VERSION}/netbird_${NETBIRD_VERSION}_linux_arm64.tar.gz"

build_arch() {
    ARCH=$1
    URL=$2
    
    echo "Building for $ARCH..."
    
    # Prepare build directory
    rm -rf ./build/app_$ARCH
    cp -r ./app ./build/app_$ARCH
    
    # Update version in manifest
    sed -i "s/VERSION_NO/$NETBIRD_VERSION/g" ./build/app_$ARCH/manifest.json
    
    # Download and extract NetBird binary
    echo "Downloading NetBird for $ARCH..."
    curl -L "$URL" -o /tmp/netbird_$ARCH.tar.gz || exit 1
    tar -xzf /tmp/netbird_$ARCH.tar.gz -C ./build/app_$ARCH/ netbird
    rm /tmp/netbird_$ARCH.tar.gz
    
    # Build Docker image
    docker build --build-arg ARCH=$ARCH --tag netbird-${NETBIRD_VERSION}-$ARCH . || exit 1
    docker cp $(docker create netbird-${NETBIRD_VERSION}-$ARCH):/opt/app/. ./build/app_$ARCH/ || exit 1
    
    # Copy .eap file to dist
    cp ./build/app_$ARCH/*.eap ./dist/ || exit 1

    echo "✓ Completed $ARCH"
}

mkdir -p ./build

build_arch armv7hf "$ARMV6_URL"
build_arch aarch64 "$ARM64_URL"

echo "Build complete for both architectures"
echo "Output files:"
ls -lh ./dist/*/*.eap
