#!/usr/bin/env bash
# kubectl, k9s, buildah, and skopeo for Debian-based CI images.
# Docker CE CLI, acr-cli, and Helm are installed earlier by install-docker-azcopy-acr.sh (Helm sits with Docker so
# we do not install Debian docker.io alongside buildah/skopeo and break docker-ce-cli).
# Run after: install-docker-azcopy-acr.sh and install-common-tooling.sh.
# Expects: Debian, curl, jq, tar, ca-certificates; TARGETARCH when set (BuildKit).

set -euxo pipefail

if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  gh_hdr=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
else
  gh_hdr=()
fi

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
case "${ARCH}" in
  amd64|arm64) ;;
  *) echo "unsupported arch for k8s/oci tooling: ${ARCH}" >&2; exit 1 ;;
esac

export DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------
# buildah + skopeo (Debian packages; lists were cleared by prior scripts).
# Use only --no-install-recommends so we do not pull podman-docker or docker.io and replace Docker CE CLI.
# ------------------------------------------------------------
apt-get update
apt-get install -y --no-install-recommends buildah skopeo
rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# kubectl (stable channel)
# ------------------------------------------------------------
KUBECTL_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" -o /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl

# ------------------------------------------------------------
# k9s (latest release; asset names use Linux_amd64 / Linux_arm64)
# ------------------------------------------------------------
K9S_TAG="$(curl -fsSL "${gh_hdr[@]}" https://api.github.com/repos/derailed/k9s/releases/latest | jq -r .tag_name)"
curl -fsSL "https://github.com/derailed/k9s/releases/download/${K9S_TAG}/k9s_Linux_${ARCH}.tar.gz" -o /tmp/k9s.tgz
tar -xzf /tmp/k9s.tgz -C /tmp k9s
install /tmp/k9s /usr/local/bin/k9s
rm -f /tmp/k9s.tgz /tmp/k9s
