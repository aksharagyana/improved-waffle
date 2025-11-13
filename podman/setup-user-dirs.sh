sudo mkdir -p /etc/podman
sudo tee /etc/podman/setup-user-dirs.sh > /dev/null <<'EOF'
#!/bin/sh
# ------------------------------------------------------------
# podman-setup-user-dirs.sh
# Run once per user the first time Podman is executed rootless.
# ------------------------------------------------------------

# The two directories we want
DIRS="$HOME/containers $HOME/.local/share/containers/storage"

for d in $DIRS; do
    # Create only if it does NOT exist yet
    [ -d "$d" ] || mkdir -p "$d"
done

# OPTIONAL: give the user a friendly hint the first time
if [ ! -f "$HOME/.podman_dirs_created" ]; then
    echo "Podman: created missing rootless directories under $HOME"
    touch "$HOME/.podman_dirs_created"
fi
EOF
