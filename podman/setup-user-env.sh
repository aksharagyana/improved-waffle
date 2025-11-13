sudo mkdir -p /etc/podman

sudo tee /etc/podman/setup-user-env.sh > /dev/null <<'EOS'
#!/bin/sh
# ------------------------------------------------------------
# podman-setup-user-env.sh
# Run once per user the first time podman is executed rootless.
# ------------------------------------------------------------

# ---- 1. Directories ------------------------------------------------
DIRS="$HOME/containers $HOME/.local/share/containers/storage"
for d in $DIRS; do
    [ -d "$d" ] || mkdir -p "$d"
done

# ---- 2. ~/.config/containers directory -----------------------------
CONFIG_DIR="$HOME/.config/containers"
[ -d "$CONFIG_DIR" ] || mkdir -p "$CONFIG_DIR"

# ---- 3. storage.conf (only if missing) -----------------------------
STORAGE_CONF="$CONFIG_DIR/storage.conf"
if [ ! -f "$STORAGE_CONF" ]; then
    cat > "$STORAGE_CONF" <<EOF
[storage]
driver = "overlay"
runroot = "$HOME/containers"
graphroot = "$HOME/.local/share/containers/storage"
[storage.options]
additionalimagestores = []
size = ""
override_kernel_check = "true"
[storage.options.overlay]
mount_program = "/usr/bin/fuse-overlayfs"
mountopt = "nodev,fsync=0"
EOF
fi

# ---- 4. containers.conf (only if missing) -------------------------
CONTAINERS_CONF="$CONFIG_DIR/containers.conf"
if [ ! -f "$CONTAINERS_CONF" ]; then
    cat > "$CONTAINERS_CONF" <<'EOF'
[containers]
netns="private"
utsns="private"
ipcns="private"
cgroupns="private"
cgroups="enabled"
log_driver="k8s-file"
events_logger="file"

[engine]
events_logger="file"
image_default_transport="docker://"
runtime="crun"
stop_timeout=10

[network]
default_rootless_network_cmd="slirp4netns"
EOF
fi

# ---- 5. One-time notice (optional) ---------------------------------
if [ ! -f "$HOME/.podman_user_setup_done" ]; then
    echo "Podman: created rootless directories & config files under $HOME"
    touch "$HOME/.podman_user_setup_done"
fi
EOS

sudo chmod +x /etc/podman/setup-user-env.sh
