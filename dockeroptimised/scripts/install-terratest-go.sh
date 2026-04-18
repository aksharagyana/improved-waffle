#!/usr/bin/env bash
# Resolve Terratest tag (latest → GitHub redirect) and install CLI + warm module cache.
set -euxo pipefail

ttv="${TERRATEST_VERSION:-latest}"
if [[ "${ttv}" == "latest" ]]; then
  ttv="$(curl -fsSL -o /dev/null -w '%{url_effective}' --max-time 120 \
    -H "User-Agent: improved-waffle-docker-build" \
    "https://github.com/gruntwork-io/terratest/releases/latest" \
    | sed -e 's,.*/,,' -e 's,[?#].*,,')"
fi

go install "github.com/gruntwork-io/terratest/cmd/terratest_log_parser@${ttv}"
mkdir -p /tmp/terratest-bootstrap
cd /tmp/terratest-bootstrap
go mod init terratest-bootstrap
go get "github.com/gruntwork-io/terratest@${ttv}"
rm -rf /tmp/terratest-bootstrap
