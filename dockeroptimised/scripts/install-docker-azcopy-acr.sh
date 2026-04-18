#!/usr/bin/env bash
# Docker CE CLI + Compose, AzCopy v10, ACR CLI (https://github.com/Azure/acr-cli), and Helm.
# Helm + acr-cli are commonly used with docker(1) for OCI charts and registry workflows; install Helm here
# (after Docker CE CLI from Docker's apt repo) so we never pull Debian's docker.io over docker-ce-cli.
# Set INSTALL_DOCKER_CLI=0 to skip Docker packages (azcopy, acr-cli, and Helm still install).
# Follow with install-common-tooling.sh then install-k8s-oci-tooling.sh for the rest of the stack.
set -euxo pipefail

gh_api_curl() {
  local attempt=1 max=8 delay=10
  local auth=()
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    auth=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
  fi
  local gh_headers=(
    -H "Accept: application/vnd.github+json"
    -H "X-GitHub-Api-Version: 2022-11-28"
    -H "User-Agent: improved-waffle-docker-build"
  )
  while [[ "${attempt}" -le "${max}" ]]; do
    if curl -fsSL "${gh_headers[@]}" "${auth[@]}" --connect-timeout 30 --max-time 180 "$@"; then
      return 0
    fi
    echo "WARNING: gh_api_curl failed (attempt ${attempt}/${max}), retrying in ${delay}s..." >&2
    sleep "${delay}"
    attempt=$((attempt + 1))
    delay=$((delay + 5))
  done
  return 1
}

curl_release_get() {
  curl -fsSL \
    --retry 10 --retry-delay 15 --retry-all-errors \
    --connect-timeout 30 --max-time 600 \
    "$@"
}

# api.github.com often returns 403 from CI/build IPs; the HTML "releases/latest" redirect still resolves the tag.
github_latest_tag_from_redirect() {
  local org_repo="$1" eff tag
  eff="$(curl -fsSL -o /dev/null -w '%{url_effective}' --max-time 120 \
    -H "User-Agent: improved-waffle-docker-build" \
    "https://github.com/${org_repo}/releases/latest")" || return 1
  tag="${eff##*/tag/}"
  tag="${tag%%\?*}"
  tag="${tag%%#*}"
  [[ -n "${tag}" ]] || return 1
  printf '%s' "${tag}"
}

github_latest_tag() {
  local org_repo="$1" json tag
  if tag="$(github_latest_tag_from_redirect "${org_repo}" 2>/dev/null)" && [[ -n "${tag}" ]]; then
    printf '%s' "${tag}"
    return 0
  fi
  if json="$(gh_api_curl "https://api.github.com/repos/${org_repo}/releases/latest" 2>/dev/null)" \
    && tag="$(printf '%s' "${json}" | jq -re .tag_name 2>/dev/null)" \
    && [[ -n "${tag}" ]]; then
    printf '%s' "${tag}"
    return 0
  fi
  return 1
}

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

AZ_TAG="$(github_latest_tag "Azure/azure-storage-azcopy")"
[[ -n "${AZ_TAG}" && "${AZ_TAG}" != "null" ]] || {
  echo "ERROR: could not resolve AzCopy release tag (GitHub API + redirect fallback failed); pass --build-arg GITHUB_TOKEN=..." >&2
  exit 1
}
AZ_VER="$(echo "${AZ_TAG}" | sed 's/^v//')"
AZ_URL="https://github.com/Azure/azure-storage-azcopy/releases/download/${AZ_TAG}/azcopy_linux_${ARCH}_${AZ_VER}.tar.gz"
curl_release_get "${AZ_URL}" -o /tmp/azcopy.tgz
tar -xzf /tmp/azcopy.tgz -C /tmp
install "/tmp/azcopy_linux_${ARCH}_${AZ_VER}/azcopy" /usr/local/bin/azcopy
rm -rf /tmp/azcopy*

case "${ARCH}" in
  amd64) acr_arch=x86_64 ;;
  arm64) acr_arch=arm64 ;;
  *) echo "Unsupported arch for acr-cli: ${ARCH}"; exit 1 ;;
esac
ACR_TAG="$(github_latest_tag "Azure/acr-cli")"
[[ -n "${ACR_TAG}" && "${ACR_TAG}" != "null" ]] || {
  echo "ERROR: could not resolve acr-cli release tag (GitHub API + redirect fallback failed); pass --build-arg GITHUB_TOKEN=..." >&2
  exit 1
}
ACR_VER="$(echo "${ACR_TAG}" | sed 's/^v//')"
ACR_URL="https://github.com/Azure/acr-cli/releases/download/${ACR_TAG}/acr-cli_${ACR_VER}_Linux_${acr_arch}.tar.gz"
curl_release_get "${ACR_URL}" -o /tmp/acr-cli.tgz
tar -xzf /tmp/acr-cli.tgz -C /tmp
install /tmp/acr-cli /usr/local/bin/acr-cli
ln -sf /usr/local/bin/acr-cli /usr/local/bin/acr
rm -f /tmp/acr-cli.tgz /tmp/acr-cli

# ------------------------------------------------------------
# Helm (get.helm.sh) — after Docker CE CLI + acr-cli for registry/OCI flows that use docker + helm together
# ------------------------------------------------------------
HELM_TAG="$(github_latest_tag "helm/helm")"
[[ -n "${HELM_TAG}" && "${HELM_TAG}" != "null" ]] || {
  echo "ERROR: could not resolve Helm release tag (GitHub API + redirect fallback failed); pass --build-arg GITHUB_TOKEN=..." >&2
  exit 1
}
curl_release_get "https://get.helm.sh/helm-${HELM_TAG}-linux-${ARCH}.tar.gz" -o /tmp/helm.tgz
tar -xzf /tmp/helm.tgz -C /tmp
install "/tmp/linux-${ARCH}/helm" /usr/local/bin/helm
rm -rf /tmp/helm.tgz "/tmp/linux-${ARCH}"
