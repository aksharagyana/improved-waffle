#!/usr/bin/env bash
# Terratest v2 removed cmd/terratest_log_parser. Keep this CLI on the root module.
set -euo pipefail

module=github.com/gruntwork-io/terratest
ttv="${TERRATEST_VERSION:-v1.0.1}"
if [[ "$ttv" == latest ]]; then
  # Go resolves the original module independently of the new modules/*/v2 releases.
  ttv="$(go list -m -f '{{.Version}}' "${module}@latest")"
fi
if ! [[ "$ttv" =~ ^v[01]\.[0-9]+\.[0-9]+$ ]]; then
  echo "ERROR: TERRATEST_VERSION must be a v0/v1 root-module release (default v1.0.1)." >&2
  echo "Terratest v2 modules do not contain terratest_log_parser." >&2
  exit 1
fi

GOBIN=/usr/local/bin go install "${module}/cmd/terratest_log_parser@${ttv}"
/usr/local/bin/terratest_log_parser --help >/dev/null

# Warm the compatible library cache without leaving a bootstrap module behind.
bootstrap_dir="$(mktemp -d)"
trap 'rm -rf "$bootstrap_dir"' EXIT
cd "$bootstrap_dir"
go mod init terratest-bootstrap
go get "${module}@${ttv}"
