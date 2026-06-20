#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=== Step 1: Updating package lists ==="
sudo apt-get update 

echo "=== Step 2: Installing core utilities ==="
sudo apt-get install -y curl wget tar

echo "=== Step 3: Installing Python environment ==="
sudo apt-get install -y python3-pip python-is-python3

echo "=== Step 4: Installing RISC-V GCC Toolchain ==="
sudo apt-get install -y gcc-riscv64-unknown-elf build-essential

echo "=== Step 5: Downloading and installing OSS CAD Suite ==="
# Fetches the latest nightly release tarball URL directly from the GitHub API
TARBALL_URL=$(curl -s https://api.github.com/repos/YosysHQ/oss-cad-suite-build/releases/latest | grep "browser_download_url.*linux-x64-.*\.tgz" | cut -d '"' -f 4)

# Download to a temporary location
wget -q "$TARBALL_URL" -O /tmp/oss-cad-suite.tgz

# Extract directly to /opt/ (a standard Linux directory for add-on software)
sudo tar -xzf /tmp/oss-cad-suite.tgz -C /opt/

# Clean up the downloaded archive
rm /tmp/oss-cad-suite.tgz

echo "=== Environment Setup Complete! ==="