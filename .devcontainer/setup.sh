#!/bin/bash
# Stop execution if any command fails
set -e

echo "Installing apt dependencies..."
sudo apt-get update 
sudo apt-get install -y python3-pip python-is-python3 gcc-riscv64-unknown-elf build-essential curl wget tar

echo "Downloading OSS CAD Suite..."
curl -s https://api.github.com/repos/YosysHQ/oss-cad-suite-build/releases/latest | grep "browser_download_url.*linux-x64-.*\.tgz" | cut -d '"' -f 4 | wget -qi -

echo "Extracting tools..."
tar -xzf oss-cad-suite-linux-x64-*.tgz -C /opt/
rm oss-cad-suite-linux-x64-*.tgz

echo "Setup complete!"