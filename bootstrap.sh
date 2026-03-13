#!/usr/bin/env bash
set -euo pipefail

# bootstrap.sh — Installs minimum dependencies then hands off to OpenTofu.
# Run this on a fresh Ubuntu 22.04 machine to reproduce the full dev environment.

REPO_URL="git@github.com:ericmjalbert/terraform-managed-ubuntu.git"
REPO_DIR="$HOME/Documents/terraform-managed-ubuntu"

echo "==> Installing OpenTofu..."
if ! command -v tofu &>/dev/null; then
    sudo snap install --classic opentofu
fi
echo "    OpenTofu $(tofu version | head -1)"

echo "==> Installing git..."
if ! command -v git &>/dev/null; then
    sudo apt-get update -qq && sudo apt-get install -y -qq git
fi
echo "    $(git --version)"

echo "==> Installing Go..."
if ! command -v go &>/dev/null; then
    GO_VERSION="1.24.1"
    curl -sLO "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
    rm "go${GO_VERSION}.linux-amd64.tar.gz"
    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
    grep -q '/usr/local/go/bin' ~/.bashrc || \
        echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc
fi
echo "    $(go version)"

echo "==> Cloning repo..."
if [ ! -d "$REPO_DIR" ]; then
    git clone "$REPO_URL" "$REPO_DIR"
else
    echo "    Repo already exists at $REPO_DIR"
fi

echo "==> Running tofu init && tofu apply..."
cd "$REPO_DIR"
tofu init
tofu apply

echo "==> Done! Dev environment is configured."
