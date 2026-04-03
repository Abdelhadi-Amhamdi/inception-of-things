#!/bin/sh

set -e

echo "[INFO] Installing K3s (agent mode)..."

SERVER_IP="192.168.56.110"

# Wait until token is available
TOKEN=""
while [ -z "$TOKEN" ]; do
  echo "[INFO] Waiting for server token via SSH..."
  TOKEN=$(ssh -o StrictHostKeyChecking=no vagrant@192.168.56.110 "sudo cat /var/lib/rancher/k3s/server/node-token" 2>/dev/null)
  
  if [ -z "$TOKEN" ]; then
    echo "[INFO] Token not ready yet, retrying in 3 seconds..."
    sleep 3
  fi
done


echo "[INFO] Connecting to server at $SERVER_IP"

# Install K3s agent
curl -sfL https://get.k3s.io | K3S_URL="https://$SERVER_IP:6443" K3S_TOKEN="$TOKEN" sh -

echo "[INFO] Agent joined the cluster!"

# Install kubectl (optional on worker)
# ln -sf /usr/local/bin/k3s /usr/local/bin/kubectl