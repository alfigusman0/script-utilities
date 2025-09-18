#!/bin/bash

# Fungsi untuk konfirmasi y/n
confirm() {
    while true; do
        read -p "$1 (y/n): " choice
        case "$choice" in
            y|Y ) return 0;;
            n|N ) return 1;;
            * ) echo "Input tidak valid, silakan masukkan y atau n.";;
        esac
    done
}

# Pastikan curl terinstal
if ! command -v curl &> /dev/null; then
    echo "curl belum terinstal. Menginstal sekarang..."
    sudo apt update && sudo apt install curl -y
fi

# Fetch versi NVM terbaru secara dinamis
echo "Mengecek versi NVM terbaru..."
LATEST_NVM=$(curl -sL https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z "$LATEST_NVM" ]; then
    echo "Gagal mendapatkan versi NVM terbaru. Menggunakan default v0.40.3."
    LATEST_NVM="v0.40.3"
fi
echo "Versi NVM terbaru: $LATEST_NVM"

# Check apakah NVM sudah terinstal
if command -v nvm &> /dev/null; then
    echo "NVM sudah terinstal."
    CURRENT_NVM_VERSION=$(nvm --version)
    echo "Versi saat ini: $CURRENT_NVM_VERSION"
    if confirm "Apakah ingin upgrade NVM ke versi terbaru ($LATEST_NVM)?"; then
        echo "Mengupgrade NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$LATEST_NVM/install.sh | bash
        # Reload NVM setelah upgrade
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi
else
    echo "NVM belum terinstal. Menginstal sekarang..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$LATEST_NVM/install.sh | bash
    # Load NVM setelah instalasi
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# Pastikan NVM sudah dimuat
if ! command -v nvm &> /dev/null; then
    echo "Gagal memuat NVM. Silakan restart terminal atau jalankan 'source ~/.bashrc' secara manual."
    exit 1
fi

# Check apakah Node.js sudah terinstal
if command -v node &> /dev/null; then
    CURRENT_NODE=$(node -v)
    echo "Node.js sudah terinstal: $CURRENT_NODE"
    if confirm "Apakah ingin upgrade ke versi LTS terbaru?"; then
        echo "Mengupgrade Node.js ke LTS terbaru..."
        nvm install --lts --reinstall-packages-from=node
        nvm use --lts
        nvm alias default node
    fi
else
    echo "Node.js belum terinstal."
    if confirm "Apakah ingin menginstall Node.js?"; then
        echo "Daftar versi LTS tersedia:"
        nvm ls-remote --lts
        read -p "Masukkan versi LTS yang ingin diinstall (contoh: --lts untuk terbaru, atau 20 untuk v20.x.x): " VERSION
        if [ -z "$VERSION" ]; then
            echo "Tidak ada versi yang dimasukkan. Membatalkan instalasi."
        else
            echo "Menginstall Node.js versi $VERSION..."
            nvm install $VERSION
            nvm use $VERSION
            nvm alias default $VERSION
        fi
    fi
fi

# Check apakah NPM tersedia
if ! command -v npm &> /dev/null; then
    echo "NPM tidak tersedia (mungkin Node.js tidak terinstal). Melewati pengecekan PM2."
    exit 0
fi

# Upgrade NPM ke versi terbaru
echo "Mengecek versi NPM saat ini..."
CURRENT_NPM=$(npm -v)
echo "Versi NPM saat ini: $CURRENT_NPM"
if confirm "Apakah ingin upgrade NPM ke versi terbaru?"; then
    echo "Mengupgrade NPM..."
    npm install -g npm@latest
fi

# Check apakah PM2 sudah terinstal
if command -v pm2 &> /dev/null; then
    echo "PM2 sudah terinstal."
    CURRENT_PM2=$(pm2 -v)
    echo "Versi saat ini: $CURRENT_PM2"
    if confirm "Apakah ingin upgrade PM2 ke versi terbaru?"; then
        echo "Mengupgrade PM2..."
        npm update -g pm2
    fi
    # Check apakah PM2 startup sudah diatur
    if ! systemctl is-enabled pm2-$(whoami) &> /dev/null; then
        echo "PM2 startup belum diatur."
        if confirm "Apakah ingin mengatur PM2 startup untuk berjalan otomatis saat boot?"; then
            echo "Mengatur PM2 startup..."
            pm2 startup
            echo "Silakan salin dan jalankan perintah yang ditampilkan di atas sebagai root (menggunakan sudo)."
        fi
    else
        echo "PM2 startup sudah diatur."
    fi
else
    echo "PM2 belum terinstal."
    if confirm "Apakah ingin menginstall PM2?"; then
        echo "Menginstall PM2..."
        npm install -g pm2
        # Setelah instalasi, atur PM2 startup
        if confirm "Apakah ingin mengatur PM2 startup untuk berjalan otomatis saat boot?"; then
            echo "Mengatur PM2 startup..."
            pm2 startup
            echo "Silakan salin dan jalankan perintah yang ditampilkan di atas sebagai root (menggunakan sudo)."
        fi
    fi
fi

echo "Proses selesai."