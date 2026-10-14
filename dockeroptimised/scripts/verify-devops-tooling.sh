#!/usr/bin/env bash
# Offline smoke check: no cloud credentials or running cluster required.
set -euo pipefail
for tool in aws monaco glab az kubectl k9s helm jq git curl docker azcopy acr-cli \
  tenv pkenv pulumi sops terrascan age sqlcmd terraform-docs tflint buildah skopeo vault \
  dig nslookup ip ss ping nc netstat traceroute mtr tcpdump nmap socat openssl; do
  command -v "$tool" >/dev/null || { echo "Missing tool: $tool" >&2; exit 1; }
done
aws --version
monaco version
glab --version
az version
kubectl version --client
helm version --short
k9s version
python3 --version
case "${1:-}" in
  python) python --version; pip --version ;;
  node) node --version; npm --version ;;
  *) echo "Usage: $0 python|node" >&2; exit 1 ;;
esac
echo "DevOps tooling smoke check passed."
