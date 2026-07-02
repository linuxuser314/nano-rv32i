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

# Add OSS CAD Suite to the path for all users
echo 'export PATH="/opt/oss-cad-suite/bin:$PATH"' | sudo tee -a /etc/bash.bashrc

#Add tools directory to the path.
echo 'export PATH="/workspaces/nano-rv32i/tools:$PATH"' >> ~/.bashrc
# Add NANO_ROOT environment variable
echo 'export NANO_ROOT="/workspaces/nano-rv32i"' >> ~/.bashrc

echo "=== Environment Setup Complete! ==="

#This is the script I used to install sv2v, but I need to test it for integration into my Codespace!
#wget https://github.com/zachjs/sv2v/releases/latest/download/sv2v-Linux.zip
#unzip sv2v-Linux.zip
#sudo mv sv2v-Linux/sv2v /usr/local/bin/