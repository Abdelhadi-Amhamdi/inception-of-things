#!/usr/bin/env bash
set -euo pipefail

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
if k3d cluster list | grep -q "iot-bonus"; then
    echo "K3d cluster 'iot-bonus' already exists. Skipping cluster creation."
else
    echo "Creating K3d cluster named 'iot-bonus'..."
    k3d cluster create --config k3d-config.yaml
fi



if command -v helm &>/dev/null; then
    echo "Helm is already installed. Skipping Helm installation."
else
    echo "Installing Helm (latest version)..."

    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    sudo ./get_helm.sh
    rm -f get_helm.sh
    # Verify installation
    helm version
fi

# Add the official stable charts repo
helm repo add stable https://charts.helm.sh/stable

# Add Bitnami repo (has many useful charts)
helm repo add bitnami https://charts.bitnami.com/bitnami

# Add GitLab repo (for your bonus project)
helm repo add gitlab https://charts.gitlab.io/

# Update all repos
helm repo update


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

echo "Patching ArgoCD server to run in insecure mode..."
kubectl -n argocd patch deployment argocd-server \
  --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--insecure"}]'
kubectl rollout status deployment/argocd-server -n argocd --timeout=120s


kubectl apply -f argocd-ingress.yaml

# Display access information
echo ""
echo "========================================="
echo "Argo CD Installation Complete!"
echo "========================================="
echo ""
echo "Access Argo CD UI:"
echo "  Username: admin"
echo "  Password: $ARGO_PASSWORD"
echo ""
echo "To stop port-forwarding:"
echo "  kill \$(cat argo-port-forward.pid)"
echo "========================================="