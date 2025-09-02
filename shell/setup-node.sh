#!/bin/bash
set -e

# Update sistem
sudo apt update && sudo apt upgrade -y
sudo apt install curl build-essential -y

# Install NVM
export NVM_VERSION="v0.39.7"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh | bash

# Load NVM ke environment
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Install Node.js LTS terbaru
nvm install --lts
nvm alias default lts/*

# Install PM2
npm install -g pm2

# Setup PM2 agar auto-start saat reboot
pm2 startup systemd -u $USER --hp $HOME
pm2 save

echo ""
echo "✅ Install selesai!"
echo "Versi Node.js : $(node -v)"
echo "Versi NPM     : $(npm -v)"
echo "Versi PM2     : $(pm2 -v)"
echo ""
echo "👉 Gunakan: pm2 start app.js --name my-app"
echo "👉 Lihat proses: pm2 ls"
