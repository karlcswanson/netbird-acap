
ARG ARCH
ARG VERSION=12.6.0
ARG UBUNTU_VERSION=24.04
ARG REPO=axisecp
ARG SDK=acap-native-sdk

# Stage 1: Download NetBird binary
FROM alpine:latest AS downloader
ARG NETBIRD_VERSION
ARG NETBIRD_ARCH

RUN apk add --no-cache curl jq tar

WORKDIR /download

RUN if [ "$NETBIRD_VERSION" = "latest" ]; then \
      RELEASE_URL="https://api.github.com/repos/netbirdio/netbird/releases/latest"; \
    else \
      RELEASE_URL="https://api.github.com/repos/netbirdio/netbird/releases/tags/v${NETBIRD_VERSION}"; \
    fi && \
    echo "Fetching NetBird $NETBIRD_VERSION for $NETBIRD_ARCH" && \
    RELEASE_JSON=$(curl -fsSL "$RELEASE_URL") && \
    ASSET_URL=$(echo "$RELEASE_JSON" | \
                jq -r ".assets[] | select(.name | test(\"linux_${NETBIRD_ARCH}\\\\.tar\\\\.gz\")) | .browser_download_url" | \
                head -1) && \
    ACTUAL_VERSION=$(echo "$RELEASE_JSON" | jq -r '.tag_name' | sed 's/^v//') && \
    echo "$ACTUAL_VERSION" > /download/VERSION && \
    echo "Downloading: $ASSET_URL (version: $ACTUAL_VERSION)" && \
    curl -fsSL "$ASSET_URL" -o netbird.tar.gz && \
    tar -xzf netbird.tar.gz && \
    chmod +x netbird

# Stage 2: Build ACAP package
FROM ${REPO}/${SDK}:${VERSION}-${ARCH}-ubuntu${UBUNTU_VERSION} AS builder

COPY app/ /opt/app/
COPY --from=downloader /download/netbird /opt/app/lib/netbird
COPY --from=downloader /download/VERSION /tmp/VERSION

RUN chmod +x /opt/app/lib/netbird && \
    NETBIRD_VERSION=$(cat /tmp/VERSION) && \
    echo "Setting manifest version to: $NETBIRD_VERSION" && \
    sed -i "s/VERSION_NO/${NETBIRD_VERSION}/g" /opt/app/manifest.json && \
    cat /opt/app/manifest.json && \
    . /opt/axis/acapsdk/environment-setup* && \
    cd /opt/app && \
    acap-build .
