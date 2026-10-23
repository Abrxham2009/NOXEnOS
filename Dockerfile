# Dockerfile for NOXEnOS Linux ISO Builder
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8

# Install all required host tools for building Ubuntu live ISOs
RUN apt-get update && apt-get install -y --no-install-recommends \
    debootstrap \
    squashfs-tools \
    xorriso \
    grub-pc-bin \
    grub-efi-amd64-bin \
    grub-common \
    mtools \
    dosfstools \
    isolinux \
    syslinux-common \
    rsync \
    curl \
    wget \
    ca-certificates \
    python3 \
    python3-pip \
    file \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

CMD ["/bin/bash", "/workspace/scripts/build-iso.sh"]
