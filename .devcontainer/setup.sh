#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=== Step 1: Updating package lists ==="
sudo apt-get update 

echo "=== Step 2: Installing core utilities ==="
# Added unzip for sv2v and liblz4-dev for Verilator FST wave compression
sudo apt-get install -y curl wget tar unzip liblz4-dev build-essential

echo "=== Step 3: Installing Python environment ==="
sudo apt-get install -y python3-pip python-is-python3

echo "=== Step 4: Installing RISC-V GCC Toolchain ==="
sudo apt-get install -y gcc-riscv64-unknown-elf

echo "=== Step 5: Downloading and installing OSS CAD Suite ==="
if [ ! -d "/opt/oss-cad-suite" ]; then
    echo "Downloading latest OSS CAD Suite..."
    TARBALL_URL=$(curl -s https://api.github.com/repos/YosysHQ/oss-cad-suite-build/releases/latest | grep "browser_download_url.*linux-x64-.*\.tgz" | cut -d '"' -f 4)
    wget -q "$TARBALL_URL" -O /tmp/oss-cad-suite.tgz
    
    echo "Extracting to /opt/..."
    sudo tar -xzf /tmp/oss-cad-suite.tgz -C /opt/
    rm /tmp/oss-cad-suite.tgz
else
    echo "⏩ OSS CAD Suite already installed in /opt/"
fi

echo "=== Step 6: Installing sv2v (SystemVerilog to Verilog Converter) ==="
if [ ! -f "/usr/local/bin/sv2v" ]; then
    wget -q https://github.com/zachjs/sv2v/releases/latest/download/sv2v-Linux.zip -O /tmp/sv2v.zip
    unzip -q /tmp/sv2v.zip -d /tmp/sv2v_extracted
    sudo mv /tmp/sv2v_extracted/sv2v /usr/local/bin/
    rm -rf /tmp/sv2v.zip /tmp/sv2v_extracted
    echo "✅ sv2v installed successfully."
else
    echo "⏩ sv2v already installed."
fi

echo "=== Step 7: Configuring Environment Paths (~/.bashrc) ==="

# Guard for NANO_ROOT
if ! grep -q "export NANO_ROOT=" ~/.bashrc; then
    echo 'export NANO_ROOT="/workspaces/nano-rv32i"' >> ~/.bashrc
    echo "✅ Added NANO_ROOT to ~/.bashrc"
fi

# Guard for OSS CAD Suite PATH
if ! grep -q "/opt/oss-cad-suite/bin" ~/.bashrc; then
    echo 'export PATH="/opt/oss-cad-suite/bin:$PATH"' >> ~/.bashrc
    echo "✅ Added OSS CAD Suite to PATH in ~/.bashrc"
fi

# Guard for custom tools PATH
if ! grep -q "/workspaces/nano-rv32i/tools" ~/.bashrc; then
    echo 'export PATH="/workspaces/nano-rv32i/tools:$PATH"' >> ~/.bashrc
    echo "✅ Added custom tools directory to PATH in ~/.bashrc"
fi
