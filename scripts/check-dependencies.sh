#!/usr/bin/env bash
# ==============================================================================
# NOXEnOS Dependency Checker
# Validates host system requirements for building the NOXEnOS ISO.
# ==============================================================================

set -eo pipefail

echo "=================================================="
echo " NOXEnOS Linux - Verificación de Dependencias"
echo "=================================================="

# Check root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "[!] AVISO: El script de compilación final requiere privilegios de root (sudo)."
fi

# Check architecture
ARCH=$(uname -m)
echo "[*] Arquitectura del host: $ARCH"
if [ "$ARCH" != "x86_64" ]; then
    echo "[!] ADVERTENCIA: La ISO de NOXEnOS está diseñada para arquitectura x86_64."
fi

# Check available disk space (minimum 15GB recommended)
AVAILABLE_GB=$(df -BG . | awk 'NR==2 {print $4}' | tr -d 'G')
echo "[*] Espacio disponible en disco: ${AVAILABLE_GB} GB"
if [ "$AVAILABLE_GB" -lt 15 ]; then
    echo "[!] ADVERTENCIA: Se recomiendan al menos 15 GB libres para compilar la ISO sin errores."
else
    echo "[+] Espacio suficiente disponible."
fi

# Check required binaries
REQUIRED_PKGS=(
    "debootstrap:debootstrap"
    "mksquashfs:squashfs-tools"
    "xorriso:xorriso"
    "grub-mkrescue:grub-common"
    "mcopy:mtools"
    "mkfs.vfat:dosfstools"
    "curl:curl"
    "tar:tar"
    "rsync:rsync"
)

MISSING_PKGS=()

for item in "${REQUIRED_PKGS[@]}"; do
    CMD="${item%%:*}"
    PKG="${item##*:}"
    if command -v "$CMD" >/dev/null 2>&1; then
        echo "[+] Comando '$CMD' encontrado."
    else
        echo "[-] Comando '$CMD' NO encontrado (paquete: $PKG)."
        MISSING_PKGS+=("$PKG")
    fi
done

# Check EFI boot files availability
if [ -d "/usr/lib/grub/x86_64-efi" ] || [ -d "/usr/lib/ISOLINUX" ]; then
    echo "[+] Módulos de arranque GRUB/ISOLINUX disponibles."
else
    echo "[-] Recomendado instalar: grub-pc-bin grub-efi-amd64-bin isolinux syslinux-common"
    MISSING_PKGS+=("grub-pc-bin" "grub-efi-amd64-bin" "isolinux" "syslinux-common")
fi

echo "--------------------------------------------------"
if [ ${#MISSING_PKGS[@]} -eq 0 ]; then
    echo "[OK] Todas las herramientas requeridas están instaladas."
    exit 0
else
    echo "[!] Paquetes que falta instalar en el sistema anfitrión:"
    echo "    sudo apt update && sudo apt install -y ${MISSING_PKGS[*]}"
    exit 1
fi
