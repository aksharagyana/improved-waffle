#!/bin/sh
set -e

echo "=== terraform-docs.sh script started ==="
echo "Current directory: $(pwd)"
echo "Script location: $0"
echo "Generating terraform documentation..."

# Check if project has custom terraform-docs config, otherwise use default
if [ -f ".terraform-docs.yml" ]; then
  echo "Using project-specific terraform-docs configuration"
  terraform-docs . --config-file .terraform-docs.yml
elif [ -f ".terraform-docs.yaml" ]; then
  echo "Using project-specific terraform-docs configuration"
  terraform-docs . --config-file .terraform-docs.yaml
else
  echo "Using default terraform-docs configuration (Inputs and Outputs only)"
  terraform-docs markdown table --output-file README.md --output-mode inject .
fi

echo "Terraform documentation updated"

# Check if README.md was modified and commit/push if so
if git diff --quiet README.md; then
  echo "No changes to README.md"
else
  echo "README.md has been updated, committing and pushing changes..."
  git add README.md
  git commit -m "docs: update terraform documentation [skip ci]"
  # Configure git remote with authentication
  echo "Configuring git remote with authentication for docs update..."
  
  # Try deploy token first, fallback to CI_JOB_TOKEN
  if [ -n "${DEPLOY_TOKEN}" ] && [ -n "${DEPLOY_TOKEN_USER}" ]; then
    echo "Using deploy token authentication..."
    echo "DEPLOY_TOKEN_USER: ${DEPLOY_TOKEN_USER}"
    echo "CI_PROJECT_PATH: ${CI_PROJECT_PATH}"
    git remote set-url origin "https://${DEPLOY_TOKEN_USER}:${DEPLOY_TOKEN}@gitlab.com/${CI_PROJECT_PATH}.git"
  else
    echo "Using CI_JOB_TOKEN authentication..."
    echo "CI_PROJECT_PATH: ${CI_PROJECT_PATH}"
    git remote set-url origin "https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.com/${CI_PROJECT_PATH}.git"
  fi
  
  echo "Current git remote configuration:"
  git remote -v
  git push origin "$CI_COMMIT_REF_NAME"
  echo "README.md changes committed and pushed to $CI_COMMIT_REF_NAME"
fi
