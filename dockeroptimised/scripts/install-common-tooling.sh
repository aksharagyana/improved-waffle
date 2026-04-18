#!/usr/bin/env bash
# Shared IaC/tooling for Debian-based CI images (pkenv, Pulumi, SOPS, Terraform stack, …).
# Dockerfile order: Azure CLI (RUN) → install-docker-azcopy-acr.sh (Docker CLI, azcopy, acr-cli, Helm) → this script → install-k8s-oci-tooling.sh.
# Expects: apt deps already installed (curl, jq, git, python3, pipx, build-essential, …).
# Uses TARGETARCH when set (Docker BuildKit); otherwise infers from uname.

set -euxo pipefail

# When you run tenv later (e.g. tenv tofu install), a token avoids GitHub API rate limits.
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  export TENV_GITHUB_TOKEN="${GITHUB_TOKEN}"
fi

# Authenticated requests when GITHUB_TOKEN is set (e.g. docker build --build-arg GITHUB_TOKEN=...).
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

# GitHub release assets occasionally return 502/504; retries cover transient CDN errors.
curl_release_get() {
  curl -fsSL \
    --retry 10 --retry-delay 15 --retry-all-errors \
    --connect-timeout 30 --max-time 600 \
    "$@"
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

# ------------------------------------------------------------
# pkenv
# ------------------------------------------------------------
git clone --depth=1 https://github.com/iamhsa/pkenv.git /root/.pkenv

# ------------------------------------------------------------
# Pulumi
# ------------------------------------------------------------
curl -fsSL https://get.pulumi.com | sh

# ------------------------------------------------------------
# SOPS
# ------------------------------------------------------------
sver="${SOPS_VERSION:-latest}"
if [[ "${sver}" == "latest" ]]; then
  sver="$(github_latest_tag "getsops/sops")"
fi
curl_release_get "https://github.com/getsops/sops/releases/download/${sver}/sops-${sver}.linux.${ARCH}" -o /usr/local/bin/sops
chmod +x /usr/local/bin/sops

# ------------------------------------------------------------
# Terrascan
# ------------------------------------------------------------
tarch="${ARCH}"
if [[ "${tarch}" == "amd64" ]]; then tarch="x86_64"; fi
if [[ "${TERRASCAN_VERSION:-latest}" == "latest" ]]; then
  TERRASCAN_TAG="$(github_latest_tag "tenable/terrascan")"
  TERRASCAN_FILE_VERSION="${TERRASCAN_TAG#v}"
else
  TERRASCAN_TAG="${TERRASCAN_VERSION}"
  case "${TERRASCAN_TAG}" in
    v*) TERRASCAN_FILE_VERSION="${TERRASCAN_TAG#v}" ;;
    *) TERRASCAN_FILE_VERSION="${TERRASCAN_TAG}" ;;
  esac
fi
TERRASCAN_URL="https://github.com/tenable/terrascan/releases/download/${TERRASCAN_TAG}/terrascan_${TERRASCAN_FILE_VERSION}_Linux_${tarch}.tar.gz"
curl_release_get "${TERRASCAN_URL}" -o /tmp/terrascan.tar.gz
tar -xzf /tmp/terrascan.tar.gz -C /tmp terrascan
install /tmp/terrascan /usr/local/bin/terrascan
rm -rf /tmp/terrascan*

# ------------------------------------------------------------
# age
# ------------------------------------------------------------
if [[ "${AGE_VERSION:-latest}" == "latest" ]]; then
  age_tag="$(github_latest_tag "FiloSottile/age")"
  AGE_URL="https://github.com/FiloSottile/age/releases/download/${age_tag}/age-${age_tag}-linux-${ARCH}.tar.gz"
else
  AGE_URL="https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/age-${AGE_VERSION}-linux-${ARCH}.tar.gz"
fi
curl_release_get "${AGE_URL}" -o /tmp/age.tar.gz
tar -xzf /tmp/age.tar.gz -C /tmp
install /tmp/age/age /usr/local/bin/age
install /tmp/age/age-keygen /usr/local/bin/age-keygen
rm -rf /tmp/age*

# ------------------------------------------------------------
# Microsoft sqlcmd
# ------------------------------------------------------------
if [[ "${SQLCMD_VERSION:-latest}" == "latest" ]]; then
  SQLCMD_TAG="$(github_latest_tag "microsoft/go-sqlcmd")"
else
  case "${SQLCMD_VERSION}" in
    v*) SQLCMD_TAG="${SQLCMD_VERSION}" ;;
    *) SQLCMD_TAG="v${SQLCMD_VERSION}" ;;
  esac
fi
SQLCMD_URL="https://github.com/microsoft/go-sqlcmd/releases/download/${SQLCMD_TAG}/sqlcmd-linux-${ARCH}.tar.bz2"
curl_release_get "${SQLCMD_URL}" -o /tmp/sqlcmd.tar.bz2
tar -xjf /tmp/sqlcmd.tar.bz2 -C /tmp
install /tmp/sqlcmd /usr/local/bin/sqlcmd
rm -f /tmp/sqlcmd*

# ------------------------------------------------------------
# terraform-docs + tflint + pre-commit
# ------------------------------------------------------------
pipx install pre-commit
pipx ensurepath
tdver="${TFDOCS_VERSION:-latest}"
if [[ "${tdver}" == "latest" ]]; then
  tdver="$(github_latest_tag "terraform-docs/terraform-docs")"
fi
os_lower="$(uname -s | tr '[:upper:]' '[:lower:]')"
curl_release_get "https://github.com/terraform-docs/terraform-docs/releases/download/${tdver}/terraform-docs-${tdver}-${os_lower}-${ARCH}.tar.gz" -o /tmp/terraform-docs.tar.gz
tar -xzf /tmp/terraform-docs.tar.gz -C /tmp
install /tmp/terraform-docs /usr/local/bin/terraform-docs
rm -rf /tmp/terraform-docs*
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# ------------------------------------------------------------
# tenv (OpenTofu/terraform/… version manager; install runtimes with tenv at runtime, e.g. tenv tofu install)
# ------------------------------------------------------------
case "${ARCH}" in
  amd64|arm64) ;;
  *) echo "ERROR: Unsupported architecture for tenv: ${ARCH}"; exit 1 ;;
esac
TENV_TAG="$(github_latest_tag "tofuutils/tenv")"
[[ -n "${TENV_TAG}" ]] || { echo "ERROR: could not resolve tenv release tag"; exit 1; }
# Asset names include the leading v, e.g. tenv_v4.10.1_amd64.deb
TENV_DEB_URL="https://github.com/tofuutils/tenv/releases/download/${TENV_TAG}/tenv_${TENV_TAG}_${ARCH}.deb"
[[ -n "${TENV_DEB_URL}" ]] || { echo "ERROR: No tenv .deb URL for arch ${ARCH}"; exit 1; }
curl_release_get "${TENV_DEB_URL}" -o /tmp/tenv.deb
dpkg -i /tmp/tenv.deb
rm -f /tmp/tenv.deb
tenv version
