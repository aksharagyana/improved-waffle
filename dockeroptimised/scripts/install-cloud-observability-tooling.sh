#!/usr/bin/env bash
# Add AWS, Dynatrace configuration management, GitLab, and network diagnostics.
# Debian-based images; requires curl, unzip, and ca-certificates.
set -euo pipefail

arch="${TARGETARCH:-$(uname -m)}"
case "$arch" in
  amd64|x86_64) arch=amd64; aws_arch=x86_64 ;;
  arm64|aarch64) arch=arm64; aws_arch=aarch64 ;;
  *) echo "Unsupported architecture: $arch" >&2; exit 1 ;;
esac

download() {
  curl --fail --silent --show-error --location --retry 5 --retry-all-errors \
    --connect-timeout 30 --max-time 600 "$@"
}

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  glab dnsutils iproute2 iputils-ping netcat-openbsd net-tools \
  traceroute mtr-tiny tcpdump nmap socat openssl less groff
rm -rf /var/lib/apt/lists/*

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

# AWS CLI v2 has a bundled Python runtime, independent of the image's Python.
aws_version="${AWS_CLI_VERSION:-latest}"
aws_suffix=""
if [[ "$aws_version" != latest ]]; then
  [[ "$aws_version" =~ ^2\.[0-9]+\.[0-9]+$ ]] || {
    echo "AWS_CLI_VERSION must be latest or a v2 version such as 2.34.0" >&2; exit 1;
  }
  aws_suffix="-${aws_version}"
fi
download "https://awscli.amazonaws.com/awscli-exe-linux-${aws_arch}${aws_suffix}.zip" -o "$workdir/aws.zip"
unzip -q "$workdir/aws.zip" -d "$workdir"
"$workdir/aws/install" --update --install-dir /usr/local/aws-cli --bin-dir /usr/local/bin

# Resolve latest once so the executable and checksum always use the same release.
monaco_version="${MONACO_VERSION:-latest}"
release_root=https://github.com/Dynatrace/dynatrace-configuration-as-code/releases
if [[ "$monaco_version" == latest ]]; then
  release_url="$(download -o /dev/null -w '%{url_effective}' "$release_root/latest")"
  monaco_version="${release_url##*/}"
fi
[[ "$monaco_version" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  echo "Invalid Monaco release: $monaco_version" >&2; exit 1;
}
monaco_version="v${monaco_version#v}"
asset="monaco-linux-${arch}"
download "$release_root/download/$monaco_version/$asset" -o "$workdir/$asset"
download "$release_root/download/$monaco_version/$asset.sha256" -o "$workdir/$asset.sha256"
(cd "$workdir" && sha256sum --check "$asset.sha256")
install -m 0755 "$workdir/$asset" /usr/local/bin/monaco

aws --version
monaco version
glab --version
