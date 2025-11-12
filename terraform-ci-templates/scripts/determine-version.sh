#!/bin/bash
set -e

echo "Determining version bump from commit messages..."

# Get commits since last tag
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [ -n "$LAST_TAG" ]; then
  COMMITS=$(git log --pretty=format:"%s" ${LAST_TAG}..HEAD)
else
  COMMITS=$(git log --pretty=format:"%s")
fi

echo "Commits since last tag:"
echo "$COMMITS"

# Determine version bump type
MAJOR_BUMP=false
MINOR_BUMP=false
PATCH_BUMP=false

# Check for breaking changes
if echo "$COMMITS" | grep -qE "^(feat|fix|perf|refactor)(\(.+\))?!:" || echo "$COMMITS" | grep -q "BREAKING CHANGE:"; then
  MAJOR_BUMP=true
  echo "Major version bump detected (breaking changes)"
elif echo "$COMMITS" | grep -qE "^(feat)(\(.+\))?:"; then
  MINOR_BUMP=true
  echo "Minor version bump detected (new features)"
elif echo "$COMMITS" | grep -qE "^(fix|perf|refactor)(\(.+\))?:"; then
  PATCH_BUMP=true
  echo "Patch version bump detected (bug fixes, performance, refactoring)"
else
  PATCH_BUMP=true
  echo "Patch version bump detected (default for other changes)"
fi

# Get current version
if [ -n "$LAST_TAG" ]; then
  CURRENT_VERSION=${LAST_TAG#v}  # Remove 'v' prefix if present
else
  CURRENT_VERSION="0.0.0"
fi

echo "Current version: $CURRENT_VERSION"

# Parse version components
MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1)
MINOR=$(echo "$CURRENT_VERSION" | cut -d. -f2)
PATCH=$(echo "$CURRENT_VERSION" | cut -d. -f3)

# Calculate new version
if [ "$MAJOR_BUMP" = true ]; then
  NEW_MAJOR=$((MAJOR + 1))
  NEW_MINOR=0
  NEW_PATCH=0
elif [ "$MINOR_BUMP" = true ]; then
  NEW_MAJOR=$MAJOR
  NEW_MINOR=$((MINOR + 1))
  NEW_PATCH=0
else
  NEW_MAJOR=$MAJOR
  NEW_MINOR=$MINOR
  NEW_PATCH=$((PATCH + 1))
fi

NEW_VERSION="${NEW_MAJOR}.${NEW_MINOR}.${NEW_PATCH}"

echo "New version: $NEW_VERSION"

# Create version file for other jobs
cat > set_version.sh << EOF
#!/bin/bash
export NEW_VERSION="$NEW_VERSION"
export CURRENT_VERSION="$CURRENT_VERSION"
export MAJOR_BUMP="$MAJOR_BUMP"
export MINOR_BUMP="$MINOR_BUMP"
export PATCH_BUMP="$PATCH_BUMP"
EOF

chmod +x set_version.sh

echo "Version determination completed: $NEW_VERSION"
