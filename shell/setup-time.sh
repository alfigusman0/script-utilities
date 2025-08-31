#!/bin/bash
# Script setup timezone Asia/Jakarta + sinkronisasi waktu dengan Chrony

echo "[*] Set timezone ke Asia/Jakarta..."
sudo timedatectl set-timezone Asia/Jakarta

echo "[*] Update repository & install Chrony..."
sudo apt update -y
sudo apt install chrony -y

echo "[*] Aktifkan dan jalankan Chrony..."
sudo systemctl enable chrony --now

echo "[*] Cek status waktu..."
timedatectl

echo "[*] Cek tracking Chrony..."
chronyc tracking

echo "[*] Daftar server NTP yang dipakai:"
chronyc sources -v
