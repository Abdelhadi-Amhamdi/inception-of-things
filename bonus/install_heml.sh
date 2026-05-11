# Download and run the official Helm install script

if command -v helm &>/dev/null; then
    echo "Helm is already installed. Skipping Helm installation."
else
    echo "Installing Helm (latest version)..."

    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    sudo ./get_helm.sh
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