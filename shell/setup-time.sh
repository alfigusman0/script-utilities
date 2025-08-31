#!/bin/bash
# Script setup timezone Asia/Jakarta + sinkronisasi waktu dengan Chrony (pool Indonesia)

echo "[*] Set timezone ke Asia/Jakarta..."
sudo timedatectl set-timezone Asia/Jakarta

echo "[*] Update repository & install Chrony..."
sudo apt update -y
sudo apt install chrony -y

echo "[*] Backup konfigurasi Chrony lama..."
sudo cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.bak.$(date +%F-%H%M%S)

echo "[*] Tulis ulang konfigurasi Chrony dengan NTP Pool Indonesia..."
sudo bash -c 'cat > /etc/chrony/chrony.conf <<EOF
# Chrony config dengan NTP Pool Indonesia
pool 0.id.pool.ntp.org iburst
pool 1.id.pool.ntp.org iburst
pool 2.id.pool.ntp.org iburst
pool 3.id.pool.ntp.org iburst

# Allow local system clock fallback
fallbackdrift

# Local hardware clock (RTC)
rtcsync

# Log
logdir /var/log/chrony
EOF'

echo "[*] Restart Chrony dengan konfigurasi baru..."
sudo systemctl restart chrony
sudo systemctl enable chrony --now

echo "[*] Status waktu sekarang:"
timedatectl

echo "[*] Tracking Chrony:"
chronyc tracking

echo "[*] Daftar server NTP yang dipakai:"
chronyc sources -v
