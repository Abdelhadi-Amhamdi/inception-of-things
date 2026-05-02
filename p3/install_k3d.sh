#!/usr/bin/env bash
set -euo pipefail

# Script: install_docker_k3d.sh
# Description: Automates installation of Docker, K3d, and common dependencies
#              on a Linux development VM (supports Debian/Ubuntu, RHEL/CentOS/Fedora, etc.)
# Author: Assistant
# Version: 1.0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if running with sudo or as root
check_privileges() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run with sudo or as root. Please run: sudo $0"
    fi
}

# Detect Linux distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO_ID="$ID"
        DISTRO_VERSION_ID="$VERSION_ID"
        DISTRO_NAME="$NAME"
    else
        error "Cannot detect Linux distribution (/etc/os-release not found)."
    fi

    info "Detected distribution: $DISTRO_NAME $DISTRO_VERSION_ID"
}

# Install common dependencies (curl, ca-certificates, gnupg, lsb-release, etc.)
install_dependencies() {
    info "Installing required system dependencies..."

    case "$DISTRO_ID" in
        ubuntu|debian)
            apt-get update -y
            apt-get install -y curl ca-certificates gnupg lsb-release wget
            ;;
        rhel|centos|fedora|rocky|almalinux)
            if command -v dnf &>/dev/null; then
                dnf install -y curl ca-certificates gnupg wget
            else
                yum install -y curl ca-certificates gnupg wget
            fi
            ;;
        *)
            error "Unsupported distribution: $DISTRO_ID. This script supports Debian/Ubuntu and RHEL/CentOS/Fedora families."
            ;;
    esac
}

# Install Docker using the official convenience script (get.docker.com)
install_docker() {
    if command -v docker &>/dev/null; then
        info "Docker is already installed. Skipping Docker installation."
        return
    fi

    info "Installing Docker using official script..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm -f get-docker.sh

    # Start and enable Docker service
    systemctl enable docker
    systemctl start docker

    # Add the user who invoked sudo to docker group (if not root)
    if [[ -n "$SUDO_USER" ]]; then
        usermod -aG docker "$SUDO_USER"
        info "User '$SUDO_USER' added to the 'docker' group."
        warn "You may need to log out and back in, or run 'newgrp docker' to use Docker without sudo."
    else
        warn "Running as root directly. No user added to docker group. Consider adding your user manually."
    fi

    info "Docker installed successfully."
}

# Install K3d (latest version)
install_k3d() {
    if command -v k3d &>/dev/null; then
        info "K3d is already installed. Skipping K3d installation."
        return
    fi

    info "Installing K3d (latest version)..."

    # Detect architecture
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)
            K3D_ARCH="amd64"
            ;;
        aarch64|arm64)
            K3D_ARCH="arm64"
            ;;
        *)
            error "Unsupported architecture: $ARCH. K3d only supports amd64 and arm64."
            ;;
    esac

    K3D_URL="https://github.com/k3d-io/k3d/releases/latest/download/k3d-linux-${K3D_ARCH}"
    curl -fsSL "$K3D_URL" -o /usr/local/bin/k3d
    chmod +x /usr/local/bin/k3d

    info "K3d installed successfully: $(k3d version)"
}

# Optional: Install kubectl (latest stable)
install_kubectl() {
    if command -v kubectl &>/dev/null; then
        info "kubectl is already installed. Skipping."
        return
    fi

    info "Installing kubectl (latest stable)..."

    # Download latest stable version
    KUBECTL_URL="https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')/kubectl"
    curl -fsSL "$KUBECTL_URL" -o /usr/local/bin/kubectl
    chmod +x /usr/local/bin/kubectl

    info "kubectl installed successfully: $(kubectl version --client --short)"
}

# Verify installations
verify_installations() {
    info "Verifying installations..."

    if command -v docker &>/dev/null; then
        docker_version=$(docker --version)
        info "Docker: $docker_version"
    else
        warn "Docker command not found. Something went wrong."
    fi

    if command -v k3d &>/dev/null; then
        k3d_version=$(k3d version)
        info "K3d: $k3d_version"
    else
        warn "K3d command not found."
    fi

    if command -v kubectl &>/dev/null; then
        kubectl_version=$(kubectl version --client --short 2>/dev/null || kubectl version --client)
        info "kubectl: $kubectl_version"
    else
        warn "kubectl not installed (optional)."
    fi
}

# Main function
main() {
    check_privileges
    detect_distro
    install_dependencies
    install_docker
    install_k3d

    # Ask user if they want kubectl
    read -p "Do you want to install kubectl (recommended for K8s interaction)? [Y/n]: " -r INSTALL_KUBECTL
    if [[ "$INSTALL_KUBECTL" =~ ^[Yy]$ ]] || [[ -z "$INSTALL_KUBECTL" ]]; then
        install_kubectl
    else
        info "Skipping kubectl installation."
    fi

    verify_installations

    info "All done! Please log out and back in (or run 'newgrp docker') to use Docker without sudo."
    info "You can now create a K3d cluster: k3d cluster create mycluster"
}

main "$@"