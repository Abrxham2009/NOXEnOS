#!/usr/bin/env bash
# ==============================================================================
# NOXEnOS Linux - Master ISO Build Engine
# Reproducible livecd builder based on Ubuntu 24.04 LTS (Noble Numbat)
# Generates bootable UEFI & Legacy BIOS hybrid ISO with Calamares & KDE Plasma.
# ==============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configuration
DISTRO_NAME="NOXEnOS"
DISTRO_CODENAME="noble"
DISTRO_VERSION="2026.1"
UBUNTU_MIRROR="http://archive.ubuntu.com/ubuntu"
WORK_DIR="$PROJECT_ROOT/build_work"
ROOTFS_DIR="$WORK_DIR/rootfs"
ISO_DIR="$WORK_DIR/iso"
OUTPUT_DIR="$PROJECT_ROOT/output"
LOG_FILE="$OUTPUT_DIR/build.log"
FINAL_ISO="$OUTPUT_DIR/${DISTRO_NAME}.iso"

mkdir -p "$OUTPUT_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=========================================================="
echo "    NOXEnOS Linux - Generador de Imagen ISO Oficial       "
echo "    Versión: $DISTRO_VERSION | Base: Ubuntu $DISTRO_CODENAME       "
echo "    Inicio de compilación: $(date)                        "
echo "=========================================================="

# 1. Privileges check
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Este script debe ejecutarse con privilegios de root (sudo)." >&2
    exit 1
fi

# 2. Cleanup trap for virtual mounts
cleanup() {
    echo "[*] Limpiando montajes virtuales..."
    for m in "$ROOTFS_DIR/dev/pts" "$ROOTFS_DIR/dev" "$ROOTFS_DIR/proc" "$ROOTFS_DIR/sys" "$ROOTFS_DIR/run"; do
        if mountpoint -q "$m" 2>/dev/null; then
            umount -lf "$m" 2>/dev/null || true
        fi
    done
}
trap cleanup EXIT INT TERM

# 3. Clean previous work dirs if requested or prepare fresh
echo "[*] Preparando directorios de trabajo en $WORK_DIR..."
cleanup
rm -rf "$WORK_DIR"
mkdir -p "$ROOTFS_DIR" "$ISO_DIR/casper" "$ISO_DIR/boot/grub" "$ISO_DIR/isolinux" "$ISO_DIR/EFI/BOOT"

# 4. Bootstrap base Ubuntu system
echo "[*] Creando sistema base con debootstrap (Ubuntu $DISTRO_CODENAME)..."
debootstrap --arch=amd64 --variant=minbase "$DISTRO_CODENAME" "$ROOTFS_DIR" "$UBUNTU_MIRROR"

# 5. Mount virtual filesystems inside rootfs
echo "[*] Montando /dev, /proc, /sys en el entorno chroot..."
mount --bind /dev "$ROOTFS_DIR/dev"
mount --bind /dev/pts "$ROOTFS_DIR/dev/pts"
mount -t proc none "$ROOTFS_DIR/proc"
mount -t sysfs none "$ROOTFS_DIR/sys"
mount -t tmpfs none "$ROOTFS_DIR/run"

# Configure DNS for chroot
cp /etc/resolv.conf "$ROOTFS_DIR/etc/resolv.conf"

# 6. Configure APT Repositories inside chroot
echo "[*] Configurando repositorios APT oficiales de Ubuntu LTS..."
cat << EOF > "$ROOTFS_DIR/etc/apt/sources.list"
deb $UBUNTU_MIRROR $DISTRO_CODENAME main restricted universe multiverse
deb $UBUNTU_MIRROR $DISTRO_CODENAME-updates main restricted universe multiverse
deb $UBUNTU_MIRROR $DISTRO_CODENAME-security main restricted universe multiverse
EOF

# 7. Package installation via chroot helper
echo "[*] Instalando paquetes del sistema..."
cat << 'CHROOT_PREP' > "$ROOTFS_DIR/tmp/install_packages.sh"
#!/bin/bash
set -eo pipefail
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C

apt-get update
apt-get install -y --no-install-recommends software-properties-common apt-transport-https ca-certificates gnupg

# Add universe and multiverse officially
add-apt-repository -y universe
add-apt-repository -y multiverse
apt-get update

CHROOT_PREP
chmod +x "$ROOTFS_DIR/tmp/install_packages.sh"
chroot "$ROOTFS_DIR" /tmp/install_packages.sh
rm -f "$ROOTFS_DIR/tmp/install_packages.sh"

# Install package lists
install_package_list() {
    local list_file="$1"
    echo "[*] Procesando lista de paquetes: $(basename "$list_file")..."
    local pkgs=()
    while IFS= read -r line || [ -n "$line" ]; do
        line="$(echo "$line" | sed -e 's/#.*//' -e 's/[[:space:]]//g')"
        if [ -n "$line" ]; then
            pkgs+=("$line")
        fi
    done < "$list_file"

    if [ ${#pkgs[@]} -gt 0 ]; then
        chroot "$ROOTFS_DIR" env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${pkgs[@]}"
    fi
}

install_package_list "$PROJECT_ROOT/config/packages/core.list"
install_package_list "$PROJECT_ROOT/config/packages/desktop.list"
install_package_list "$PROJECT_ROOT/config/packages/apps.list"
install_package_list "$PROJECT_ROOT/config/packages/office.list"
install_package_list "$PROJECT_ROOT/config/packages/installer.list"

# Remove unwanted bloat
echo "[*] Eliminando paquetes no deseados..."
while IFS= read -r line || [ -n "$line" ]; do
    line="$(echo "$line" | sed -e 's/#.*//' -e 's/[[:space:]]//g')"
    if [ -n "$line" ]; then
        chroot "$ROOTFS_DIR" env DEBIAN_FRONTEND=noninteractive apt-get purge -y "$line" 2>/dev/null || true
    fi
done < "$PROJECT_ROOT/config/packages/remove.list"

# 8. Configure Localization (Spanish default)
echo "[*] Configurando localización española (es_ES.UTF-8)..."
chroot "$ROOTFS_DIR" locale-gen es_ES.UTF-8
chroot "$ROOTFS_DIR" update-locale LANG=es_ES.UTF-8 LC_ALL=es_ES.UTF-8
echo "LANG=es_ES.UTF-8" > "$ROOTFS_DIR/etc/default/locale"

# Configure default keyboard layout
cat << 'EOF' > "$ROOTFS_DIR/etc/default/keyboard"
XKBMODEL="pc105"
XKBLAYOUT="es"
XKBVARIANT=""
XKBOPTIONS=""
BACKSPACE="guess"
EOF

# Timezone
echo "Europe/Madrid" > "$ROOTFS_DIR/etc/timezone"
chroot "$ROOTFS_DIR" ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime

# 9. Configure Live User and Hostname
echo "[*] Configurando usuario Live y hostname..."
echo "noxenos" > "$ROOTFS_DIR/etc/hostname"
cat << 'EOF' > "$ROOTFS_DIR/etc/hosts"
127.0.0.1   localhost
127.0.1.1   noxenos
::1         localhost ip6-localhost ip6-loopback
EOF

# Create live user
chroot "$ROOTFS_DIR" useradd -m -s /bin/bash -G sudo,adm,cdrom,audio,video,plugdev,netdev noxenos || true
chroot "$ROOTFS_DIR" passwd -d noxenos || true
echo "noxenos ALL=(ALL) NOPASSWD: ALL" > "$ROOTFS_DIR/etc/sudoers.d/noxenos"
chmod 0440 "$ROOTFS_DIR/etc/sudoers.d/noxenos"

# Enable SDDM autologin for Live session
mkdir -p "$ROOTFS_DIR/etc/sddm.conf.d"
cat << 'EOF' > "$ROOTFS_DIR/etc/sddm.conf.d/autologin.conf"
[Autologin]
User=noxenos
Session=plasma
EOF

# 10. Copy NOXEnOS Branding and Desktop Configurations
echo "[*] Integrando branding, fondos de pantalla y temas..."

# Wallpapers
mkdir -p "$ROOTFS_DIR/usr/share/wallpapers/NOXEnOS"
cp -r "$PROJECT_ROOT/branding/wallpapers/"* "$ROOTFS_DIR/usr/share/wallpapers/NOXEnOS/"

# Logos and Icons
mkdir -p "$ROOTFS_DIR/usr/share/icons/hicolor"
cp -r "$PROJECT_ROOT/branding/icons/hicolor/"* "$ROOTFS_DIR/usr/share/icons/hicolor/"
mkdir -p "$ROOTFS_DIR/usr/share/pixmaps"
cp "$PROJECT_ROOT/branding/logos/noxenos-emblem.png" "$ROOTFS_DIR/usr/share/pixmaps/noxenos.png"
cp "$PROJECT_ROOT/branding/logos/noxenos.svg" "$ROOTFS_DIR/usr/share/pixmaps/noxenos.svg"

# KDE Plasma Look and Feel & Color Schemes
mkdir -p "$ROOTFS_DIR/usr/share/color-schemes"
cp "$PROJECT_ROOT/config/desktop/plasma/NOXEnOSDark.colors" "$ROOTFS_DIR/usr/share/color-schemes/"
cp "$PROJECT_ROOT/config/desktop/plasma/NOXEnOSLight.colors" "$ROOTFS_DIR/usr/share/color-schemes/"

mkdir -p "$ROOTFS_DIR/usr/share/plasma/look-and-feel/org.noxenos.desktop"
cp -r "$PROJECT_ROOT/config/desktop/plasma/org.noxenos.desktop/"* "$ROOTFS_DIR/usr/share/plasma/look-and-feel/org.noxenos.desktop/"

# Plank Dock Theme & Configuration
mkdir -p "$ROOTFS_DIR/usr/share/plank/themes/NOXEnOS-DarkGlass"
cp "$PROJECT_ROOT/config/desktop/plank/dock.theme" "$ROOTFS_DIR/usr/share/plank/themes/NOXEnOS-DarkGlass/"

# Copy /etc/skel default profile (dock launchers, desktop icons, mimeapps, autostart)
mkdir -p "$ROOTFS_DIR/etc/skel/.config/plank/dock1/launchers"
mkdir -p "$ROOTFS_DIR/etc/skel/.config/autostart"
mkdir -p "$ROOTFS_DIR/etc/skel/Desktop"
cp "$PROJECT_ROOT/config/desktop/plank/settings" "$ROOTFS_DIR/etc/skel/.config/plank/dock1/"
cp -r "$PROJECT_ROOT/config/desktop/plank/launchers/"* "$ROOTFS_DIR/etc/skel/.config/plank/dock1/launchers/"
cp -r "$PROJECT_ROOT/config/skel/Desktop/"* "$ROOTFS_DIR/etc/skel/Desktop/"
cp -r "$PROJECT_ROOT/config/skel/.config/"* "$ROOTFS_DIR/etc/skel/.config/"

# Ensure /home/noxenos gets identical files
cp -r "$ROOTFS_DIR/etc/skel/." "$ROOTFS_DIR/home/noxenos/"
chroot "$ROOTFS_DIR" chown -R noxenos:noxenos /home/noxenos

# Copy Plymouth Boot Splash
mkdir -p "$ROOTFS_DIR/usr/share/plymouth/themes/noxenos"
cp -r "$PROJECT_ROOT/config/plymouth/noxenos/"* "$ROOTFS_DIR/usr/share/plymouth/themes/noxenos/"
chroot "$ROOTFS_DIR" update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/noxenos/noxenos.plymouth 100 || true
chroot "$ROOTFS_DIR" update-alternatives --set default.plymouth /usr/share/plymouth/themes/noxenos/noxenos.plymouth || true

# Copy SDDM Theme
mkdir -p "$ROOTFS_DIR/usr/share/sddm/themes/noxenos"
cp -r "$PROJECT_ROOT/config/sddm/noxenos/"* "$ROOTFS_DIR/usr/share/sddm/themes/noxenos/"
cat << 'EOF' > "$ROOTFS_DIR/etc/sddm.conf.d/theme.conf"
[Theme]
Current=noxenos
EOF

# Copy Calamares Installer Branding and Configurations
mkdir -p "$ROOTFS_DIR/etc/calamares/branding/noxenos"
cp -r "$PROJECT_ROOT/config/installer/calamares/branding/noxenos/"* "$ROOTFS_DIR/etc/calamares/branding/noxenos/"
cp "$PROJECT_ROOT/config/installer/calamares/settings.conf" "$ROOTFS_DIR/etc/calamares/"
mkdir -p "$ROOTFS_DIR/etc/calamares/modules"
cp -r "$PROJECT_ROOT/config/installer/calamares/modules/"* "$ROOTFS_DIR/etc/calamares/modules/"

# Install helper scripts
cp "$PROJECT_ROOT/scripts/noxo-control" "$ROOTFS_DIR/usr/local/bin/noxo-control"
cp "$PROJECT_ROOT/scripts/noxo-welcome" "$ROOTFS_DIR/usr/local/bin/noxo-welcome"
chmod +x "$ROOTFS_DIR/usr/local/bin/noxo-control" "$ROOTFS_DIR/usr/local/bin/noxo-welcome"

# Apply performance and memory optimization configs
cp "$PROJECT_ROOT/config/optimization/99-noxenos-performance.conf" "$ROOTFS_DIR/etc/sysctl.d/"
cp "$PROJECT_ROOT/config/optimization/zram-tools" "$ROOTFS_DIR/etc/default/zram-tools"

# 11. Extract Kernel and Initramfs for ISO Casper
echo "[*] Extrayendo kernel e initramfs para casper..."
KERNEL_IMG=$(ls -1 "$ROOTFS_DIR/boot/vmlinuz-"* | sort -V | tail -n 1)
INITRD_IMG=$(ls -1 "$ROOTFS_DIR/boot/initrd.img-"* | sort -V | tail -n 1)

cp "$KERNEL_IMG" "$ISO_DIR/casper/vmlinuz"
cp "$INITRD_IMG" "$ISO_DIR/casper/initrd"

# 12. Clean chroot and unmount
echo "[*] Limpiando caches de APT y archivos temporales..."
chroot "$ROOTFS_DIR" apt-get autoremove -y --purge
chroot "$ROOTFS_DIR" apt-get clean
rm -rf "$ROOTFS_DIR/tmp/"* "$ROOTFS_DIR/var/tmp/"*
rm -f "$ROOTFS_DIR/etc/resolv.conf"
cleanup

# 13. Create Squashfs Filesystem
echo "[*] Creando sistema de archivos comprimido (Squashfs XZ)..."
mksquashfs "$ROOTFS_DIR" "$ISO_DIR/casper/filesystem.squashfs" -comp xz -noappend -b 1048576

# Create filesystem size and manifest
printf $(du -sx --block-size=1 "$ROOTFS_DIR" | cut -f1) > "$ISO_DIR/casper/filesystem.size"
chroot "$ROOTFS_DIR" dpkg-query -W --showformat='${Package} ${Version}\n' > "$ISO_DIR/casper/filesystem.manifest" 2>/dev/null || true

# 14. Setup Bootloaders (GRUB2 & ISOLINUX)
echo "[*] Preparando cargadores de arranque UEFI y BIOS..."
cp "$PROJECT_ROOT/config/iso/boot/grub/grub.cfg" "$ISO_DIR/boot/grub/grub.cfg"
cp "$PROJECT_ROOT/config/iso/isolinux/isolinux.cfg" "$ISO_DIR/isolinux/isolinux.cfg"

# Prepare EFI boot image
dd if=/dev/zero of="$ISO_DIR/boot/grub/efi.img" bs=1M count=8
mkfs.vfat "$ISO_DIR/boot/grub/efi.img"
mmd -i "$ISO_DIR/boot/grub/efi.img" ::/EFI ::/EFI/BOOT

# Copy EFI bootloader binary if available on host, or generate via grub-mkstandalone
if [ -f "/usr/lib/grub/x86_64-efi/monolithic/grubx64.efi" ]; then
    mcopy -i "$ISO_DIR/boot/grub/efi.img" /usr/lib/grub/x86_64-efi/monolithic/grubx64.efi ::/EFI/BOOT/BOOTX64.EFI
else
    grub-mkstandalone \
        --format=x86_64-efi \
        --output="$ISO_DIR/EFI/BOOT/BOOTX64.EFI" \
        --locales="" \
        --fonts="" \
        "boot/grub/grub.cfg=$PROJECT_ROOT/config/iso/boot/grub/grub.cfg" 2>/dev/null || true
    mcopy -i "$ISO_DIR/boot/grub/efi.img" "$ISO_DIR/EFI/BOOT/BOOTX64.EFI" ::/EFI/BOOT/BOOTX64.EFI 2>/dev/null || true
fi

# ISOLINUX files
for f in isolinux.bin ldlinux.c32 libcom.c32 libutil.c32 vesamenu.c32; do
    if [ -f "/usr/lib/ISOLINUX/$f" ]; then
        cp "/usr/lib/ISOLINUX/$f" "$ISO_DIR/isolinux/"
    elif [ -f "/usr/lib/syslinux/modules/bios/$f" ]; then
        cp "/usr/lib/syslinux/modules/bios/$f" "$ISO_DIR/isolinux/"
    fi
done

# 15. Generate Hybrid ISO with Xorriso
echo "[*] Generando imagen ISO híbrida arrancable con xorriso..."
xorriso -as mkisofs \
    -r -V "${DISTRO_NAME}_${DISTRO_VERSION}" \
    -o "$FINAL_ISO" \
    -J -l -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot \
    -e boot/grub/efi.img \
    -no-emul-boot -isohybrid-gpt-basdat \
    "$ISO_DIR"

# 16. Generate Checksum
echo "[*] Calculando suma de verificación SHA-256..."
cd "$OUTPUT_DIR"
sha256sum "$(basename "$FINAL_ISO")" > "${FINAL_ISO}.sha256"

ISO_SIZE=$(du -h "$FINAL_ISO" | cut -f1)
echo "=========================================================="
echo "    ¡COMPILACIÓN DE NOXEnOS FINALIZADA CON ÉXITO!        "
echo "    Archivo: $FINAL_ISO"
echo "    Tamaño:  $ISO_SIZE"
echo "    SHA-256: $(cat "${FINAL_ISO}.sha256" | cut -d' ' -f1)"
echo "    Fecha:   $(date)"
echo "=========================================================="
