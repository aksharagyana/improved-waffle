# 1. Backup
sudo cp -r /etc/apt/sources.list /etc/apt/sources.list.d ~/apt-backup

# 2. Disable official
sudo mv /etc/apt/sources.list /etc/apt/sources.list.disabled

# 3. Add corporate mirror
sudo tee /etc/apt/sources.list.d/corp-mirror.list > /dev/null <<'EOF'
deb [trusted=yes] https://mirror.corp.example.com/ubuntu noble main restricted universe multiverse
deb [trusted=yes] https://mirror.corp.example.com/ubuntu noble-updates main restricted universe multiverse
deb [trusted=yes] https://mirror.corp.example.com/ubuntu noble-security main restricted universe multiverse
deb [trusted=yes] https://mirror.corp.example.com/ubuntu noble-backports main restricted universe multiverse
EOF

# 4. (optional) proxy
# sudo tee /etc/apt/apt.conf.d/99proxy <<< 'Acquire::http::Proxy "http://proxy.corp.example.com:3128";'

# 5. Update
sudo apt update


# =================== or strat using variables ============================

MIRROR="https://mirror.corp.example.com/ubuntu"
COMPONENTS="main restricted universe multiverse"

# set APT config variables
sudo tee /etc/apt/apt.conf.d/99corp-mirror.conf > /dev/null <<EOF
APT::Acquire::BaseURL "$MIRROR";
Deb::Components "$COMPONENTS";
EOF

# Use the variable in your .list file
sudo tee /etc/apt/sources.list.d/corp-mirror.list > /dev/null <<EOF
deb [trusted=yes] \${APT::Acquire::BaseURL} noble \${Deb::Components}
deb [trusted=yes] \${APT::Acquire::BaseURL} noble-updates \${Deb::Components}
deb [trusted=yes] \${APT::Acquire::BaseURL} noble-security \${Deb::Components}
deb [trusted=yes] \${APT::Acquire::BaseURL} noble-backports \${Deb::Components}
EOF

sudo mv /etc/apt/sources.list /etc/apt/sources.list.disabled 2>/dev/null || true
sudo apt update
# =================== or end using variables ============================
