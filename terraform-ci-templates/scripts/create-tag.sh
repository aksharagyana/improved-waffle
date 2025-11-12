#!/bin/bash
set -e

# Source version information
source set_version.sh

echo "Creating tag: $NEW_VERSION"

# Generate changelog from commit messages
echo "Generating changelog..."

# Get commits since last tag
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [ -n "$LAST_TAG" ]; then
  COMMITS=$(git log --pretty=format:"%s" ${LAST_TAG}..HEAD)
else
  COMMITS=$(git log --pretty=format:"%s")
fi

# Create changelog
CHANGELOG="## Changelog for $NEW_VERSION\n\n"

# Categorize commits
FEATURES=$(echo "$COMMITS" | grep -E "^(feat)(\(.+\))?:" | sed 's/^feat\(.*\):/- ✨ \1/' || true)
FIXES=$(echo "$COMMITS" | grep -E "^(fix)(\(.+\))?:" | sed 's/^fix\(.*\):/- 🐛 \1/' || true)
PERF=$(echo "$COMMITS" | grep -E "^(perf)(\(.+\))?:" | sed 's/^perf\(.*\):/- ⚡ \1/' || true)
REFACTOR=$(echo "$COMMITS" | grep -E "^(refactor)(\(.+\))?:" | sed 's/^refactor\(.*\):/- 🔧 \1/' || true)
DOCS=$(echo "$COMMITS" | grep -E "^(docs)(\(.+\))?:" | sed 's/^docs\(.*\):/- 📚 \1/' || true)
OTHER=$(echo "$COMMITS" | grep -vE "^(feat|fix|perf|refactor|docs)(\(.+\))?:" | sed 's/^/- 📝 /' || true)

# Build changelog sections
if [ -n "$FEATURES" ]; then
  CHANGELOG="${CHANGELOG}### ✨ Features\n${FEATURES}\n\n"
fi

if [ -n "$FIXES" ]; then
  CHANGELOG="${CHANGELOG}### 🐛 Bug Fixes\n${FIXES}\n\n"
fi

if [ -n "$PERF" ]; then
  CHANGELOG="${CHANGELOG}### ⚡ Performance\n${PERF}\n\n"
fi

if [ -n "$REFACTOR" ]; then
  CHANGELOG="${CHANGELOG}### 🔧 Refactoring\n${REFACTOR}\n\n"
fi

if [ -n "$DOCS" ]; then
  CHANGELOG="${CHANGELOG}### 📚 Documentation\n${DOCS}\n\n"
fi

if [ -n "$OTHER" ]; then
  CHANGELOG="${CHANGELOG}### 📝 Other Changes\n${OTHER}\n\n"
fi

# Add commit count
COMMIT_COUNT=$(echo "$COMMITS" | wc -l)
CHANGELOG="${CHANGELOG}---\n**Total commits:** ${COMMIT_COUNT}\n"

echo "Changelog generated:"
echo -e "$CHANGELOG"

# Create the tag with changelog (no file needed)
TAG_MESSAGE="Release $NEW_VERSION

$CHANGELOG"

git tag -a "$NEW_VERSION" -m "$TAG_MESSAGE"

# Configure git remote with authentication
echo "Configuring git remote with authentication..."

# Try deploy token first, fallback to CI_JOB_TOKEN
if [ -n "${DEPLOY_TOKEN}" ] && [ -n "${DEPLOY_TOKEN_USER}" ]; then
  echo "Using deploy token authentication..."
  echo "DEPLOY_TOKEN_USER: ${DEPLOY_TOKEN_USER}"
  echo "CI_PROJECT_PATH: ${CI_PROJECT_PATH}"
  echo "Git remote URL: https://${DEPLOY_TOKEN_USER}:${DEPLOY_TOKEN}@gitlab.com/${CI_PROJECT_PATH}.git"
  git remote set-url origin "https://${DEPLOY_TOKEN_USER}:${DEPLOY_TOKEN}@gitlab.com/${CI_PROJECT_PATH}.git"
else
  echo "Using CI_JOB_TOKEN authentication..."
  echo "CI_PROJECT_PATH: ${CI_PROJECT_PATH}"
  echo "Git remote URL: https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.com/${CI_PROJECT_PATH}.git"
  git remote set-url origin "https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.com/${CI_PROJECT_PATH}.git"
fi

# Verify the remote configuration
echo "Current git remote configuration:"
git remote -v

# Push the tag
git push origin "$NEW_VERSION"

echo "Tag $NEW_VERSION created and pushed successfully with changelog"
