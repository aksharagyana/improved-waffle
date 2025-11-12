#!/bin/bash
set -e

# Determine version - use CI_COMMIT_TAG if available, otherwise source from set_version.sh
if [ -n "$CI_COMMIT_TAG" ]; then
  echo "Using tag version: $CI_COMMIT_TAG"
  NEW_VERSION="$CI_COMMIT_TAG"
else
  echo "Using determined version from set_version.sh"
  source set_version.sh
fi

echo "Publishing module to GitLab Terraform Registry for version: $NEW_VERSION"

# Get the module package
MODULE_NAME=$(basename $(pwd))
# Convert module name to valid format (replace spaces and underscores with hyphens)
MODULE_NAME=$(echo "${MODULE_NAME}" | tr " _" -)
MODULE_SYSTEM="${TERRAFORM_MODULE_SYSTEM:-local}"  # Default system, can be overridden with TERRAFORM_MODULE_SYSTEM
PACKAGE_NAME="${MODULE_NAME}-${MODULE_SYSTEM}-${NEW_VERSION}.tgz"

# Create the package with correct naming convention
echo "Creating module package: $PACKAGE_NAME"
tar -vczf "/tmp/${PACKAGE_NAME}" -C . --exclude=./.git --exclude=./.gitlab-ci.yml --exclude=./.terraform --exclude=./*.tfstate* --exclude=./.terraform.lock.hcl --exclude=./*.log --exclude=./.DS_Store .

# Upload to GitLab Terraform Module Registry
echo "Uploading to GitLab Terraform Module Registry..."
echo "API URL: ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/terraform/modules/${MODULE_NAME}/${MODULE_SYSTEM}/${NEW_VERSION}/file"

curl --fail-with-body --location --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
     --upload-file "/tmp/${PACKAGE_NAME}" \
     "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/terraform/modules/${MODULE_NAME}/${MODULE_SYSTEM}/${NEW_VERSION}/file"

echo "Module $NEW_VERSION published to GitLab Terraform Registry successfully!"
echo "Registry URL: ${CI_PROJECT_URL}/-/terraform/modules"

# Clean up files after successful upload
rm -f "/tmp/${PACKAGE_NAME}"
rm -f version.env
rm -f set_version.sh
rm -f changelog.md
echo "Package and version files cleaned up after successful upload"
