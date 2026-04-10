#!/usr/bin/env bash
# Shared IaC/tooling for Debian-based CI images (pkenv, Pulumi, SOPS, Terraform stack, …).
# Dockerfile order: Azure CLI (RUN) → install-docker-azcopy-acr.sh → this script.
# Expects: apt deps already installed (curl, jq, git, python3, pipx, build-essential, …).
# Uses TARGETARCH when set (Docker BuildKit); otherwise infers from uname.

set -euxo pipefail

# tenv/OpenTofu install hits the GitHub API; unauthenticated builds can be rate-limited.
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  export TENV_GITHUB_TOKEN="${GITHUB_TOKEN}"
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
  sver="$(curl -s https://api.github.com/repos/getsops/sops/releases/latest | jq -r .tag_name)"
fi
curl -fsSL "https://github.com/getsops/sops/releases/download/${sver}/sops-${sver}.linux.${ARCH}" -o /usr/local/bin/sops
chmod +x /usr/local/bin/sops

# ------------------------------------------------------------
# Terrascan
# ------------------------------------------------------------
tarch="${ARCH}"
if [[ "${tarch}" == "amd64" ]]; then tarch="x86_64"; fi
if [[ "${TERRASCAN_VERSION:-latest}" == "latest" ]]; then
  TERRASCAN_TAG="$(curl -s https://api.github.com/repos/tenable/terrascan/releases/latest | jq -r .tag_name)"
  TERRASCAN_FILE_VERSION="${TERRASCAN_TAG#v}"
else
  TERRASCAN_TAG="${TERRASCAN_VERSION}"
  case "${TERRASCAN_TAG}" in
    v*) TERRASCAN_FILE_VERSION="${TERRASCAN_TAG#v}" ;;
    *) TERRASCAN_FILE_VERSION="${TERRASCAN_TAG}" ;;
  esac
fi
TERRASCAN_URL="https://github.com/tenable/terrascan/releases/download/${TERRASCAN_TAG}/terrascan_${TERRASCAN_FILE_VERSION}_Linux_${tarch}.tar.gz"
curl -fsSL "${TERRASCAN_URL}" -o /tmp/terrascan.tar.gz
tar -xzf /tmp/terrascan.tar.gz -C /tmp terrascan
install /tmp/terrascan /usr/local/bin/terrascan
rm -rf /tmp/terrascan*

# ------------------------------------------------------------
# age
# ------------------------------------------------------------
if [[ "${AGE_VERSION:-latest}" == "latest" ]]; then
  AGE_URL="$(curl -s https://api.github.com/repos/FiloSottile/age/releases/latest \
    | jq -r --arg arch "${ARCH}" '.assets[] | select(.name | test("linux-" + $arch + "[.]tar[.]gz$")) | .browser_download_url')"
else
  AGE_URL="https://github.com/FiloSottile/age/releases/download/${AGE_VERSION}/age-${AGE_VERSION}-linux-${ARCH}.tar.gz"
fi
curl -fsSL "${AGE_URL}" -o /tmp/age.tar.gz
tar -xzf /tmp/age.tar.gz -C /tmp
install /tmp/age/age /usr/local/bin/age
install /tmp/age/age-keygen /usr/local/bin/age-keygen
rm -rf /tmp/age*

# ------------------------------------------------------------
# Microsoft sqlcmd
# ------------------------------------------------------------
if [[ "${SQLCMD_VERSION:-latest}" == "latest" ]]; then
  SQLCMD_TAG="$(curl -s https://api.github.com/repos/microsoft/go-sqlcmd/releases/latest | jq -r .tag_name)"
else
  case "${SQLCMD_VERSION}" in
    v*) SQLCMD_TAG="${SQLCMD_VERSION}" ;;
    *) SQLCMD_TAG="v${SQLCMD_VERSION}" ;;
  esac
fi
SQLCMD_URL="https://github.com/microsoft/go-sqlcmd/releases/download/${SQLCMD_TAG}/sqlcmd-linux-${ARCH}.tar.bz2"
curl -fsSL "${SQLCMD_URL}" -o /tmp/sqlcmd.tar.bz2
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
  tdver="$(curl -s https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest | jq -r .tag_name)"
fi
os_lower="$(uname -s | tr '[:upper:]' '[:lower:]')"
curl -fsSL "https://github.com/terraform-docs/terraform-docs/releases/download/${tdver}/terraform-docs-${tdver}-${os_lower}-${ARCH}.tar.gz" -o /tmp/terraform-docs.tar.gz
tar -xzf /tmp/terraform-docs.tar.gz -C /tmp
install /tmp/terraform-docs /usr/local/bin/terraform-docs
rm -rf /tmp/terraform-docs*
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# ------------------------------------------------------------
# tenv + OpenTofu
# ------------------------------------------------------------
case "${ARCH}" in
  amd64|arm64) ;;
  *) echo "ERROR: Unsupported architecture for tenv: ${ARCH}"; exit 1 ;;
esac
TENV_DEB_URL="$(curl -s https://api.github.com/repos/tofuutils/tenv/releases/latest \
  | jq -r --arg a "${ARCH}" '.assets[] | select(.name | test("_" + $a + "[.]deb$")) | .browser_download_url')"
[[ -n "${TENV_DEB_URL}" ]] || { echo "ERROR: No tenv .deb asset found for arch ${ARCH}"; exit 1; }
curl -fsSL "${TENV_DEB_URL}" -o /tmp/tenv.deb
dpkg -i /tmp/tenv.deb
rm -f /tmp/tenv.deb
tenv version
tenv tofu install latest-stable
tenv tofu use latest-stable
