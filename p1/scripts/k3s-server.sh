#!/bin/sh

set -e

echo "[INFO] Installing K3s (server mode)..."

# Install K3s server
curl -sfL https://get.k3s.io | sh -

# Wait for node to be ready
sleep 5

# Setup kubeconfig for root
mkdir -p /root/.kube

# Wait for K3s to generate kubeconfig
while [ ! -f /etc/rancher/k3s/k3s.yaml ]; do
    echo "Waiting for K3s to be ready..."
    sleep 3
done

# Copy kubeconfig to shared folder for Vagrant
# cp /etc/rancher/k3s/k3s.yaml /vagrant/k3s.yaml

# Fix permissions
# chmod 600 /root/.kube/config

# Get node token (used by agents)
TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)

echo "[INFO] K3s server installed!"
echo "[INFO] Node token:"
# echo $TOKEN > /vagrant/node-token
echo $TOKEN

# Install kubectl (symlink already exists in k3s, but we make it explicit)
ln -sf /usr/local/bin/k3s /usr/local/bin/kubectl

# Test
kubectl get nodes