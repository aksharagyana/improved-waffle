# golang:latest + shared tooling + Terratest (install-common-tooling.sh)
FROM golang:latest

ARG TARGETPLATFORM
ARG TARGETARCH
ARG CACHEBUST=2026-02-23

ARG SOPS_VERSION=latest
ARG TERRASCAN_VERSION=latest
ARG AGE_VERSION=latest
ARG SQLCMD_VERSION=latest
ARG TFDOCS_VERSION=latest
ARG TERRATEST_VERSION=latest
ARG PULUMI_VERSION=latest
ARG OPENTOFU_VERSION=latest

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.tenv/bin:/root/.pkenv/bin:/root/.pulumi/bin:$PATH"
ENV SOPS_VERSION=${SOPS_VERSION}
ENV TERRASCAN_VERSION=${TERRASCAN_VERSION}
ENV AGE_VERSION=${AGE_VERSION}
ENV SQLCMD_VERSION=${SQLCMD_VERSION}
ENV TFDOCS_VERSION=${TFDOCS_VERSION}

RUN echo "Cache bust timestamp: ${CACHEBUST}" > /dev/null

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    gnupg \
    jq \
    tar \
    unzip \
    wget \
    zip \
    bzip2 \
    python3 \
    python3-pip \
    python3-venv \
    pipx \
    build-essential \
    openssh-client \
    lsb-release \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

COPY docker/scripts/install-docker-azcopy-acr.sh /tmp/install-docker-azcopy-acr.sh
COPY dockeroptimised/scripts/install-common-tooling.sh /tmp/install-common-tooling.sh
RUN chmod +x /tmp/install-docker-azcopy-acr.sh /tmp/install-common-tooling.sh \
    && /tmp/install-docker-azcopy-acr.sh \
    && /tmp/install-common-tooling.sh \
    && rm -f /tmp/install-docker-azcopy-acr.sh /tmp/install-common-tooling.sh

RUN set -eux; \
    ttv="${TERRATEST_VERSION}"; \
    if [ "$$ttv" = "latest" ]; then ttv=$$(curl -s https://api.github.com/repos/gruntwork-io/terratest/releases/latest | jq -r .tag_name); fi; \
    go install "github.com/gruntwork-io/terratest/cmd/terratest_log_parser@$$ttv" \
    && mkdir -p /tmp/terratest-bootstrap \
    && cd /tmp/terratest-bootstrap \
    && go mod init terratest-bootstrap \
    && go get "github.com/gruntwork-io/terratest@$$ttv" \
    && rm -rf /tmp/terratest-bootstrap

RUN set -eux \
    && go version \
    && terratest_log_parser --help >/dev/null \
    && python3 --version \
    && docker --version \
    && azcopy --version \
    && acr-cli version \
    && az --version | head -n1 \
    && pkenv --version \
    && pulumi version \
    && tenv version \
    && sops --version \
    && terrascan version \
    && age --version \
    && age-keygen --version \
    && sqlcmd --version \
    && terraform-docs --version \
    && tflint --version \
    && tofu --version
