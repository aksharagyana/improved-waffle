# DevOps development images

`Dockerfile.python` and `Dockerfile.node` include AWS CLI v2 (`aws`),
Dynatrace Monaco (`monaco`), and GitLab CLI (`glab`) alongside the existing
Azure CLI, Docker/Compose, AzCopy, ACR CLI, kubectl, k9s, Helm, jq, Git,
Vault, Pulumi, tenv, SOPS, and other infrastructure tools.

Network diagnostics include dig/nslookup, ip/ss, ping, nc, netstat,
traceroute, mtr, tcpdump, nmap, socat, and OpenSSL. Packet capture and some
network probes may require additional container capabilities at runtime.

Both Dockerfiles support Linux AMD64 and ARM64. The Go image also includes the full network diagnostics suite plus `telnet`,
without the AWS/Monaco/GitLab additions. The .NET and Debian Azure SQL image
definitions are unchanged. GitHub Actions currently builds only `go`, `node`, and `py`, each for both architectures
and publishes `ghcr.io/aksharagyana/improved-waffle/py:latest` and
`ghcr.io/aksharagyana/improved-waffle/node:latest` on main pushes and scheduled
builds. Pull request builds do not publish images.

## Build and verify

Run from the repository root:

```sh
docker build -f dockeroptimised/Dockerfile.python -t devops-python:local .
docker build -f dockeroptimised/Dockerfile.node -t devops-node:local .
docker run --rm devops-python:local verify-devops-tooling python
docker run --rm devops-node:local verify-devops-tooling node
```

The same smoke check runs during each image build, without credentials or
access to a cluster. It checks availability of the existing tools and runs
version commands for the cloud clients, Kubernetes tools, and language runtime.

`AWS_CLI_VERSION` and `MONACO_VERSION` build arguments default to `latest`.
Pin them to an AWS v2 release (`2.x.y`) and Monaco release (`v2.x.y`) when
reproducible versions are needed. Monaco's binary is checked against its
release SHA-256 file. GitLab CLI comes from the signed Debian package repository.
Other existing tooling continues to use the repository's existing version policy.

## Runtime authentication

Credentials are supplied at runtime; none are baked into these images.

AWS, including EKS:

```sh
docker run --rm -it -v "$HOME/.aws:/root/.aws" devops-python:local bash
aws configure sso
aws sso login --profile my-profile
aws sts get-caller-identity --profile my-profile
aws eks update-kubeconfig --name my-cluster --region eu-west-2 --profile my-profile
kubectl get namespaces
```

Mount your kubeconfig at `/root/.kube` when you want it persisted between runs.
For CI, supply AWS credentials or workload-identity configuration through your
CI platform. The AWS CLI's bundled Python runtime does not replace the image's Python.

GitLab (GitLab.com or self-managed):

```sh
glab auth login --hostname gitlab.com
# CI: provide GITLAB_TOKEN and, for self-managed installations, GITLAB_HOST.
glab auth status
glab repo clone group/project
```

Dynatrace:

```sh
monaco --help
monaco deploy manifest.yaml
```

Monaco manages Dynatrace configuration as code. Configure environment URLs
and token/OAuth environment-variable references in your Monaco manifest.
This addition provides configuration tooling, not OneAgent runtime instrumentation.
Use the existing curl/jq tools for direct Dynatrace API calls.

## Installation references

- [AWS CLI v2 installation](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Dynatrace Monaco download and verification](https://docs.dynatrace.com/docs/deliver/configuration-as-code/monaco/installation/download-monaco)
- [GitLab CLI](https://gitlab.com/gitlab-org/cli)
- [Debian glab package](https://packages.debian.org/trixie/glab)
