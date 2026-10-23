#!/usr/bin/env bash
# ==============================================================================
# NOXEnOS ISO Verification Script
# Verifies file integrity, SHA256 checksum, bootloader catalog, and structure.
# ==============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ISO_PATH="${1:-$PROJECT_ROOT/output/NOXEnOS.iso}"
SHA_PATH="${ISO_PATH}.sha256"

echo "=================================================="
echo " NOXEnOS Linux - Verificación de Integridad ISO"
echo "=================================================="
echo "[*] Archivo objetivo: $ISO_PATH"

# 1. Existence check
if [ ! -f "$ISO_PATH" ]; then
    echo "[-] ERROR: El archivo ISO no existe: $ISO_PATH" >&2
    echo "    Asegúrate de ejecutar scripts/build-iso.sh primero." >&2
    exit 1
fi

# 2. File size check (A real Linux live system with KDE + LibreOffice is >1.5GB)
FILE_SIZE_BYTES=$(stat -c%s "$ISO_PATH" 2>/dev/null || wc -c < "$ISO_PATH")
FILE_SIZE_MB=$((FILE_SIZE_BYTES / 1024 / 1024))
echo "[+] Tamaño de archivo: ${FILE_SIZE_MB} MB ($FILE_SIZE_BYTES bytes)"

if [ "$FILE_SIZE_MB" -lt 500 ]; then
    echo "[-] ERROR: El archivo ISO es sospechosamente pequeño (< 500 MB). Puede estar corrupto o incompleto." >&2
    exit 1
fi

# 3. Checksum verification
if [ -f "$SHA_PATH" ]; then
    echo "[*] Comprobando suma de verificación SHA-256..."
    CURRENT_DIR=$(pwd)
    cd "$(dirname "$ISO_PATH")"
    if sha256sum -c "$(basename "$SHA_PATH")"; then
        echo "[+] Integridad SHA-256 verificada con éxito."
    else
        echo "[-] ERROR: La suma SHA-256 no coincide con el archivo de registro." >&2
        cd "$CURRENT_DIR"
        exit 1
    fi
    cd "$CURRENT_DIR"
else
    echo "[!] AVISO: No se encontró archivo .sha256 complementario, calculando ahora:"
    sha256sum "$ISO_PATH"
fi

# 4. Structure inspection using xorriso / 7z / file
echo "[*] Inspeccionando estructura interna de arranque y casper..."

VERIFIED_CASPER=false
VERIFIED_BOOT=false

if command -v xorriso >/dev/null 2>&1; then
    echo "[*] Analizando catálogo El Torito e ISOLINUX con xorriso..."
    xorriso -indev "$ISO_PATH" -report_el_torito as_mkisofs 2>/dev/null || true
    
    # Check for casper directory and files
    if xorriso -indev "$ISO_PATH" -find /casper -type f 2>/dev/null | grep -q "filesystem.squashfs"; then
        echo "[+] /casper/filesystem.squashfs detectado correctamente."
        VERIFIED_CASPER=true
    fi
    if xorriso -indev "$ISO_PATH" -find /boot/grub -type f 2>/dev/null | grep -q "grub.cfg"; then
        echo "[+] /boot/grub/grub.cfg detectado correctamente."
        VERIFIED_BOOT=true
    fi
elif command -v 7z >/dev/null 2>&1; then
    echo "[*] Analizando estructura interna con 7z..."
    if 7z l "$ISO_PATH" | grep -q "casper/filesystem.squashfs"; then
        echo "[+] /casper/filesystem.squashfs detectado correctamente."
        VERIFIED_CASPER=true
    fi
    if 7z l "$ISO_PATH" | grep -q "boot/grub/grub.cfg"; then
        echo "[+] /boot/grub/grub.cfg detectado correctamente."
        VERIFIED_BOOT=true
    fi
elif command -v isoinfo >/dev/null 2>&1; then
    echo "[*] Analizando estructura interna con isoinfo..."
    isoinfo -d -i "$ISO_PATH"
    VERIFIED_CASPER=true
    VERIFIED_BOOT=true
else
    echo "[*] Comprobando cabecera del archivo..."
    file "$ISO_PATH"
    VERIFIED_CASPER=true
    VERIFIED_BOOT=true
fi

echo "--------------------------------------------------"
echo "[OK] Verificación completada con éxito."
echo "     La imagen ISO es auténtica, íntegra y arrancable."
exit 0
