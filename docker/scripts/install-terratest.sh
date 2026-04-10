#!/usr/bin/env bash
set -euxo pipefail
ttv="${TERRATEST_VERSION:-latest}"
if [[ "${ttv}" == "latest" ]]; then
  ttv="$(curl -s https://api.github.com/repos/gruntwork-io/terratest/releases/latest | jq -r .tag_name)"
fi
go install "github.com/gruntwork-io/terratest/cmd/terratest_log_parser@${ttv}"
mkdir -p /tmp/terratest-bootstrap
cd /tmp/terratest-bootstrap
go mod init terratest-bootstrap
go get "github.com/gruntwork-io/terratest@${ttv}"
rm -rf /tmp/terratest-bootstrap
