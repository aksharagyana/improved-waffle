sudo tee /etc/profile.d/podman-rootless.sh > /dev/null <<'EOS'
# ------------------------------------------------------------
# /etc/profile.d/podman-rootless.sh
# Sourced for every interactive login shell.
# ------------------------------------------------------------
if command -v podman >/dev/null 2>&1; then
    podman() {
        # Ensure everything is in place (idempotent)
        /etc/podman/setup-user-env.sh

        # Call the real podman binary
        command podman "$@"
    }
fi
EOS

sudo chmod 644 /etc/profile.d/podman-rootless.sh
