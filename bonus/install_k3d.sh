#!/usr/bin/env bash
set -euo pipefail



# Install system dependencies
echo "Installing required system dependencies..."
apt-get update -y
apt-get install -y curl ca-certificates gnupg lsb-release wget


# Install Docker
if command -v docker &>/dev/null; then
    echo "Docker is already installed. Skipping Docker installation."
else
    echo "Installing Docker using official script..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm -f get-docker.sh
    systemctl enable docker
    systemctl start docker
    usermod -aG docker "$SUDO_USER"
fi




# Install K3d and kubectl
if command -v k3d &>/dev/null; then
    echo "K3d is already installed. Skipping K3d installation."
else
    echo "Installing K3d (latest version)..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    chmod +x /usr/local/bin/k3d
fi


# Install kubectl
if command -v kubectl &>/dev/null; then
    echo "kubectl is already installed. Skipping."
else
    echo "Installing kubectl (latest stable)..."
    KUBECTL_URL="https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')/kubectl"
    curl -fsSL "$KUBECTL_URL" -o /usr/local/bin/kubectl
    chmod +x /usr/local/bin/kubectl
fi

# Create a K3d cluster
if k3d cluster list | grep -q "iot"; then
    echo "K3d cluster 'iot' already exists. Skipping cluster creation."
else
    echo "Creating K3d cluster named 'iot'..."
    k3d cluster create iot
fi


# Wait for cluster to be fully ready
echo "Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

echo "Installing Argo CD..."
kubectl delete namespace argocd --ignore-not-found
kubectl create namespace argocd

# Install Argo CD using the official manifest
echo "Applying Argo CD installation manifest..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.8.4/manifests/install.yaml
# Wait for Argo CD components to be ready
echo "Waiting for Argo CD pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

# Get the initial admin password
echo "Retrieving initial admin password..."
ARGO_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Argo CD initial admin password: $ARGO_PASSWORD"

# Save password to a file for later reference
echo "$ARGO_PASSWORD" > argo-password.txt
echo "Password saved to argo-password.txt"


# Set up port-forwarding to access Argo CD UI
echo "Setting up port-forwarding for Argo CD UI..."
echo "Starting port-forward in background (localhost:8080 -> argocd-server:443)"
nohup kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &
PORT_FORWARD_PID=$!
echo $PORT_FORWARD_PID > argo-port-forward.pid
echo "Port-forwarding started with PID: $PORT_FORWARD_PID"


# Display access information
echo ""
echo "========================================="
echo "Argo CD Installation Complete!"
echo "========================================="
echo ""
echo "Access Argo CD UI:"
echo "  URL: https://localhost:8080"
echo "  Username: admin"
echo "  Password: $ARGO_PASSWORD"
echo ""
echo "To stop port-forwarding:"
echo "  kill \$(cat argo-port-forward.pid)"
echo "========================================="