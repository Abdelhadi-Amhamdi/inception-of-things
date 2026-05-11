#!/bin/sh
set -e

apt update && apt install -y curl

echo "[INFO] Installing K3s (server mode)..."

if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
  echo "[INFO] Removing previous K3s install..."
  /usr/local/bin/k3s-uninstall.sh
fi

curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.28.15+k3s1" INSTALL_K3S_EXEC="server" sh -s - \
  --token 12345 \
  --write-kubeconfig-mode 644 \
  --bind-address 192.168.56.110 \
  --advertise-address 192.168.56.110 \
  --node-ip 192.168.56.110

while [ ! -f /etc/rancher/k3s/k3s.yaml ]; do
    echo "Waiting for K3s to be ready..."
    sleep 3
done

ln -sf /usr/local/bin/k3s /usr/local/bin/kubectl