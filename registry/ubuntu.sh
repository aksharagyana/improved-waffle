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
