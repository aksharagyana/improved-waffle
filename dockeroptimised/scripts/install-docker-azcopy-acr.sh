#!/usr/bin/env bash
# Docker CE CLI + Compose plugin, AzCopy v10, ACR CLI — Debian-based images only.
# Set INSTALL_DOCKER_CLI=0 to skip Docker packages (e.g. if unused); azcopy/acr always install.
set -euxo pipefail

resolve_arch() {
  local arch="${TARGETARCH:-}"
  if [[ -z "${arch}" ]]; then
    case "$(uname -m)" in
      x86_64) arch=amd64 ;;
      aarch64) arch=arm64 ;;
      *) echo "unknown arch: $(uname -m)"; exit 1 ;;
    esac
  fi
  printf '%s' "${arch}"
}

ARCH="$(resolve_arch)"

if [[ "${INSTALL_DOCKER_CLI:-1}" != "0" ]]; then
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" \
    | tee /etc/apt/sources.list.d/docker.list >/dev/null
  apt-get update
  apt-get install -y --no-install-recommends docker-ce-cli docker-compose-plugin
  rm -rf /var/lib/apt/lists/*
fi

AZ_TAG="$(curl -s https://api.github.com/repos/Azure/azure-storage-azcopy/releases/latest | jq -r .tag_name)"
AZ_VER="$(echo "${AZ_TAG}" | sed 's/^v//')"
AZ_URL="https://github.com/Azure/azure-storage-azcopy/releases/download/${AZ_TAG}/azcopy_linux_${ARCH}_${AZ_VER}.tar.gz"
curl -fsSL "${AZ_URL}" -o /tmp/azcopy.tgz
tar -xzf /tmp/azcopy.tgz -C /tmp
install "/tmp/azcopy_linux_${ARCH}_${AZ_VER}/azcopy" /usr/local/bin/azcopy
rm -rf /tmp/azcopy*

case "${ARCH}" in
  amd64) acr_arch=x86_64 ;;
  arm64) acr_arch=arm64 ;;
  *) echo "Unsupported arch for acr-cli: ${ARCH}"; exit 1 ;;
esac
ACR_TAG="$(curl -s https://api.github.com/repos/Azure/acr-cli/releases/latest | jq -r .tag_name)"
ACR_VER="$(echo "${ACR_TAG}" | sed 's/^v//')"
ACR_URL="https://github.com/Azure/acr-cli/releases/download/${ACR_TAG}/acr-cli_${ACR_VER}_Linux_${acr_arch}.tar.gz"
curl -fsSL "${ACR_URL}" -o /tmp/acr-cli.tgz
tar -xzf /tmp/acr-cli.tgz -C /tmp
install /tmp/acr-cli /usr/local/bin/acr-cli
ln -sf /usr/local/bin/acr-cli /usr/local/bin/acr
rm -f /tmp/acr-cli.tgz /tmp/acr-cli
