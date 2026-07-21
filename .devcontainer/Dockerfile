FROM ubuntu:24.04

# Prevent apt-get from hanging on interactive timezone/user prompts
ENV DEBIAN_FRONTEND=noninteractive

# 1. Environment Variables (Replaces ~/.bashrc and devcontainer.json injection)
# These are permanently available to any shell or GitHub Action using this image.
ENV NANO_ROOT="/workspaces/nano-rv32i"
ENV PATH="/opt/oss-cad-suite/bin:$NANO_ROOT/tools:$PATH"

# 2. Pin Tool Versions (Update these dates/tags when you want to upgrade)
ARG OSS_CAD_VERSION="20260718" 
ARG SV2V_VERSION="v0.0.11"
ARG RISCV_FORMAL_BRANCH="master"

# 3. Install Core System Dependencies & Python
RUN apt-get update && apt-get install -y \
    curl wget tar unzip liblz4-dev build-essential \
    python3-pip python-is-python3 \
    gcc-riscv64-unknown-elf \
    && rm -rf /var/lib/apt/lists/*

# 4. Install OSS CAD Suite
RUN wget -q "https://github.com/YosysHQ/oss-cad-suite-build/releases/download/${OSS_CAD_VERSION}/oss-cad-suite-linux-x64-${OSS_CAD_VERSION}.tgz" -O /tmp/oss-cad-suite.tgz && \
    tar -xzf /tmp/oss-cad-suite.tgz -C /opt/ && \
    rm /tmp/oss-cad-suite.tgz

# 5. Install sv2v
# WARNING: This statically pulls the x86-64 Linux binary. 
# If run on an Apple Silicon Mac, Docker will automatically emulate it via Rosetta 2.
RUN wget -q "https://github.com/zachjs/sv2v/releases/download/${SV2V_VERSION}/sv2v-Linux.zip" -O /tmp/sv2v.zip && \
    unzip -q /tmp/sv2v.zip -d /tmp/sv2v_extracted && \
    mv /tmp/sv2v_extracted/sv2v-Linux/sv2v /usr/local/bin/ && \
    rm -rf /tmp/sv2v.zip /tmp/sv2v_extracted

# 6. Install Python Packages
RUN pip install numpy fastcrc msgspec --break-system-packages

# 7. Pre-fetch riscv-formal to /opt/ (Safe from the workspace volume mount)
RUN mkdir -p /opt/riscv-formal && \
    curl -sL "https://api.github.com/repos/YosysHQ/riscv-formal/tarball/${RISCV_FORMAL_BRANCH}" | tar -xz -C /opt/riscv-formal --strip-components=1

# Set the default directory when the container opens
WORKDIR $NANO_ROOT