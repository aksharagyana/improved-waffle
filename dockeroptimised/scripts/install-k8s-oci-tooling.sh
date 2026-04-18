#!/usr/bin/env bash
# kubectl, k9s, buildah, and skopeo for Debian-based CI images.
# Docker CE CLI, acr-cli, and Helm are installed earlier by install-docker-azcopy-acr.sh (Helm sits with Docker so
# we do not install Debian docker.io alongside buildah/skopeo and break docker-ce-cli).
# Run after: install-docker-azcopy-acr.sh and install-common-tooling.sh.
# Expects: Debian, curl, jq, tar, ca-certificates; TARGETARCH when set (BuildKit).

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
KUBECTL_VERSION="$(curl_release_get https://dl.k8s.io/release/stable.txt)"
curl_release_get "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" -o /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl

# ------------------------------------------------------------
# k9s (latest release; asset names use Linux_amd64 / Linux_arm64)
# ------------------------------------------------------------
K9S_TAG="$(github_latest_tag "derailed/k9s")"
[[ -n "${K9S_TAG}" && "${K9S_TAG}" != "null" ]] || {
  echo "ERROR: could not resolve k9s release tag (redirect + API failed); pass --build-arg GITHUB_TOKEN=..." >&2
  exit 1
}
curl_release_get "https://github.com/derailed/k9s/releases/download/${K9S_TAG}/k9s_Linux_${ARCH}.tar.gz" -o /tmp/k9s.tgz
tar -xzf /tmp/k9s.tgz -C /tmp k9s
install /tmp/k9s /usr/local/bin/k9s
rm -f /tmp/k9s.tgz /tmp/k9s
