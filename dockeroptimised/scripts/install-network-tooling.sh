#!/usr/bin/env bash
# Network diagnostics for Debian-based development images.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates curl wget jq openssh-client \
  dnsutils iproute2 iputils-ping netcat-openbsd net-tools \
  traceroute mtr-tiny tcpdump nmap socat openssl inetutils-telnet
rm -rf /var/lib/apt/lists/*

# Fail the image build if any expected command is missing.
for tool in curl wget jq ssh dig nslookup ip ss ping nc netstat \
  traceroute mtr tcpdump nmap socat openssl telnet; do
  command -v "$tool" >/dev/null || { echo "Missing network tool: $tool" >&2; exit 1; }
done
echo "Network tooling smoke check passed."
