sudo tee /etc/profile.d/podman-rootless.sh > /dev/null <<'EOF'
# ------------------------------------------------------------
# /etc/profile.d/podman-rootless.sh
# Sourced for every interactive login shell.
# ------------------------------------------------------------
if command -v podman >/dev/null 2>&1; then
    # Run the helper *only* when podman is actually invoked
    podman() {
        # 1. Ensure directories exist (idempotent)
        /etc/podman/setup-user-dirs.sh

        # 2. Call the real podman binary
        command podman "$@"
    }
fi
EOF
