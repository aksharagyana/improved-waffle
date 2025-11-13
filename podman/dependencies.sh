sudo apt-get update
sudo apt-get download podman uidmap slirp4netns fuse-overlayfs catatonit conmon crun
sudo apt-get download buildah
sudo apt-get install --download-only --reinstall -y \
  podman uidmap slirp4netns fuse-overlayfs catatonit conmon crun

cp /var/cache/apt/archives/*.deb ~/output/

# Fix 4: Configure Podman for rootless
print_status "Fix 4: Configuring Podman for rootless mode..."

# Create Podman configuration directory
mkdir -p ~/.local/share/containers/storage
mkdir -p ~/.config/containers
mkdir -p /run/user/$(id -u)/containers

# Create containers.conf for rootless
cat > ~/.config/containers/containers.conf << 'EOF'
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

mkdir -p "$HOME/.config/containers" && cat > "$HOME/.config/containers/storage.conf" << EOF
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

# Create storage.conf for rootless
cat > ~/.config/containers/storage.conf << 'EOF'
[storage]
driver = "overlay"
runroot = "/run/user/1000/containers"
graphroot = "/home/$USER/.local/share/containers/storage"

[storage.options]
additionalimagestores = []
size = ""
override_kernel_check = "true"

[storage.options.overlay]
mount_program = "/usr/bin/fuse-overlayfs"
mountopt = "nodev,fsync=0"
EOF

export CONTAINERS_CONF="$HOME/.config/containers/containers.conf"
export CONTAINERS_STORAGE_CONF="$HOME/.config/containers/storage.conf"
export PODMAN_SYSTEMD_UNIT=""
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export TMPDIR="/tmp"

sudo tee /etc/apparmor.d/usr.bin.podman > /dev/null <<'EOF'
# Minimal working AppArmor profile for Podman rootless mode
#include <tunables/global>

profile usr.bin.podman flags=(attach_disconnected,mediate_deleted) {
  # Allow everything for now except unsafe mounts
  capability,
  network,
  file,
  umount,
  ptrace,
  signal,
  dbus,
  mount,
  rlimit,

  # Allow library access
  /usr/lib/x86_64-linux-gnu/** rix,

  # Allow user-space libraries and configs
  @{HOME}/** rix,

  # Include local overrides
  # (your local file above will be read here)
  #include if exists <local/usr.bin.podman>
}
EOF

cat > /etc/apparmor.d/usr.bin.crun <<'EOF'
# AppArmor profile for crun (Podman OCI runtime)
# Compatible with Ubuntu 24.x hardened systems
# Maintainer-safe structure: includes <local/usr.bin.crun> for overrides

#include <tunables/global>

profile crun /usr/bin/crun {
  # Include standard abstractions
  # These bring in common safe rules for libraries, DNS, users, etc.
  #include <abstractions/base>
  #include <abstractions/nameservice>
  #include <abstractions/user-tmp>

  # Allow standard system binaries/libraries
  /usr/bin/**        rix,
  /usr/lib/**        rmix,
  /lib/**            rmix,
  /usr/libexec/**    rmix,

  # Config and runtime directories
  /etc/**            r,
  /run/**            rw,
  @{PROC}/**         r,
  @{sys}/**          r,

  # Needed for container sockets and temp work
  /var/run/**        rw,
  @{TEMPORARYDIR}/** rw,

  # Networking permissions
  network inet stream,
  network inet6 stream,
  network unix stream,

  # Capabilities typically required by container runtimes
  capability sys_admin,
  capability sys_ptrace,
  capability sys_chroot,
  capability setgid,
  capability setuid,
  capability dac_override,
  capability audit_write,
  capability mknod,
  capability net_bind_service,

  # Allow crun's libcrun to re-execute via memfd
  /memfd: rw,

  # Allow reading /dev/null and /dev/urandom
  /dev/null rw,
  /dev/urandom r,

  # Logging access
  /var/log/** rwk,

  # Signals and process control
  signal (send,receive) peer=unconfined,
  ptrace (read,readby,trace,traceby),

  # Default deny for unknown paths
  deny /** w,

  # Include site-specific overrides
  # This file is not overwritten by system updates
  #include <local/usr.bin.crun>
}
EOF
