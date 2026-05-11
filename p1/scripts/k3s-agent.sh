#!/bin/sh

set -e

apt update && apt install -y curl

echo "[INFO] Installing K3s (agent mode)..."

SERVER_IP="192.168.56.110"

echo "[INFO] Connecting to server at $SERVER_IP"

curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.28.15+k3s1" K3S_URL="https://$SERVER_IP:6443" K3S_TOKEN="12345" sh -

echo "[INFO] Agent joined the cluster!"
