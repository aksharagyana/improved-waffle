#!/usr/bin/env bash
# hashicorp vault for Debian-based CI images.


set -euxo pipefail

apt-get update && apt-get install -y \
    wget \
    gpg \
    lsb-release \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

wget -O- https://apt.releases.hashicorp.com/gpg \
    | gpg --dearmor \
    > /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com \
    $(. /etc/os-release && echo $VERSION_CODENAME) main" \
    > /etc/apt/sources.list.d/hashicorp.list

apt-get update && apt-get install -y vault \
    && rm -rf /var/lib/apt/lists/*