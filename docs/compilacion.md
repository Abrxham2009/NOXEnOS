# Guía de Compilación de la ISO de NOXEnOS Linux

Este documento detalla el procedimiento para generar de forma reproducible la imagen ISO arrancable e instalable de **NOXEnOS Linux**.

---

## 1. Requisitos del sistema para la compilación

Para compilar la ISO se requieren las siguientes características en el equipo de compilación:
- **Arquitectura:** x86_64 (AMD64).
- **Procesador:** 2 núcleos o más (recomendado 4 núcleos).
- **Memoria RAM:** Mínimo 4 GB (recomendado 8 GB).
- **Espacio en disco libre:** Mínimo 15 GB de espacio libre (el proceso descarga paquetes y crea el sistema de archivos comprimido).
- **Conexión a Internet:** Necesaria para descargar los paquetes oficiales de Ubuntu LTS.
- **Privilegios:** Acceso administrativo (`sudo`) para ejecutar `chroot`, montar pseudo-sistemas de archivos (`/proc`, `/dev`) y crear nodos de dispositivo.

> **Nota técnica fundamental sobre Windows:**  
> Un sistema operativo Windows puro no puede crear un sistema de archivos raíz de Linux de forma directa debido a diferencias en los permisos POSIX, llamadas al sistema `mknod` para crear nodos de dispositivo y la incapacidad de hacer `chroot` nativo del kernel Linux.  
> Por ello, en entornos Windows se debe utilizar **WSL 2**, **Docker** o una **máquina virtual Linux** en VirtualBox, tal como se detalla a continuación.

---

## 2. Métodos de compilación

### Método A: Usando WSL 2 en Windows 11 (Recomendado para Windows)

1. Abre **PowerShell** como Administrador y asegúrate de tener una distribución Ubuntu en WSL 2:
   ```powershell
   wsl --install -d Ubuntu-24.04
   ```
2. Una vez instalado y configurado el usuario, accede al directorio del proyecto desde la terminal de Ubuntu WSL:
   ```bash
   cd /mnt/c/Users/Abraham/Downloads/NOXEnOS
   ```
3. Instala las herramientas de compilación necesarias:
   ```bash
   sudo bash scripts/check-dependencies.sh
   # Si faltan paquetes:
   sudo apt update && sudo apt install -y debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools dosfstools isolinux syslinux-common
   ```
4. Ejecuta el motor de compilación:
   ```bash
   sudo bash scripts/build-iso.sh
   ```
5. Al terminar, la imagen estará disponible en:
   ```text
   C:\Users\Abraham\Downloads\NOXEnOS\output\NOXEnOS.iso
   ```

---

### Método B: Usando Docker (Cualquier sistema operativo)

Si tienes Docker instalado (Docker Desktop en Windows o Docker Engine en Linux):

1. En la raíz del proyecto, ejecuta el script de construcción por contenedor:
   ```bash
   bash scripts/build-in-docker.sh
   ```
   *O alternativamente en PowerShell de Windows:*
   ```powershell
   docker build -t noxenos-builder .
   docker run --rm --privileged -v "${PWD}:/workspace" noxenos-builder /bin/bash /workspace/scripts/build-iso.sh
   ```
2. El contenedor se encarga de aislar todas las dependencias y dejará la ISO en la carpeta `output/`.

---

### Método C: En un sistema Linux nativo (Ubuntu 24.04 / 22.04 o Debian)

1. Clona o copia la carpeta `NOXEnOS` a tu equipo Linux.
2. Abre una terminal dentro del directorio:
   ```bash
   cd NOXEnOS
   ```
3. Verifica las dependencias:
   ```bash
   bash scripts/check-dependencies.sh
   ```
4. Lanza la compilación como superusuario:
   ```bash
   sudo bash scripts/build-iso.sh
   ```

---

## 3. Fases del proceso automatizado (`build-iso.sh`)

El script maestro realiza 16 pasos controlados:

1. **Verificación de permisos:** Asegura que se ejecuta como root y define trampas de señal (`trap cleanup`) para desmontar `/proc`, `/sys` y `/dev` si el proceso se interrumpe.
2. **Preparación del espacio de trabajo:** Limpia compilaciones anteriores en `build_work/`.
3. **Debootstrap:** Descarga e inicializa la estructura de directorios raíz con la base `noble` (Ubuntu 24.04 LTS).
4. **Montajes virtuales:** Monta dinámicamente `/dev`, `/dev/pts`, `/proc`, `/sys` y `/run`.
5. **Configuración de repositorios:** Configura `sources.list` con los canales `main`, `restricted`, `universe`, `multiverse`, actualizaciones y seguridad.
6. **Instalación de paquetes por listas:** Lee e instala en orden los paquetes de `config/packages/`:
   - `core.list` (kernel Linux, casper, systemd, red, audio PipeWire).
   - `desktop.list` (KDE Plasma, KWin, Plank, fuentes Inter y Noto).
   - `apps.list` (Firefox, Dolphin, VLC, Gwenview, Spectacle, Discover).
   - `office.list` (LibreOffice Writer, Calc, Impress, Draw, Math, Base y diccionarios en español).
   - `installer.list` (Calamares y dependencias de particionado).
7. **Purga de paquetes superfluos:** Elimina juegos o paquetes no deseados listados en `remove.list`.
8. **Configuración de idioma:** Genera la localización `es_ES.UTF-8`, zona horaria `Europe/Madrid` y distribución de teclado española.
9. **Creación del usuario Live:** Crea el usuario `noxenos` sin contraseña permanente, con sudo sin clave y autologin configurado en SDDM.
10. **Inyección de Branding y Personalización:**
    - Instala los 5 fondos de pantalla en `/usr/share/wallpapers/NOXEnOS/`.
    - Copia los esquemas de color `NOXEnOSDark` y `NOXEnOSLight`.
    - Instala el tema de dock `NOXEnOS-DarkGlass` y los 9 lanzadores fijados.
    - Configura el tema animado de Plymouth y la pantalla de inicio SDDM.
    - Copia las configuraciones a `/etc/skel/` y `/home/noxenos/`.
11. **Instalación de utilidades:** Copia `noxo-control` y `noxo-welcome` a `/usr/local/bin/`.
12. **Ajustes de rendimiento:** Configura ZRAM y `99-noxenos-performance.conf` en sysctl.
13. **Extracción del Kernel e Initramfs:** Copia los archivos del kernel a `iso/casper/vmlinuz` e `iso/casper/initrd`.
14. **Compresión SquashFS:** Comprime el sistema raíz mediante `mksquashfs` con compresión `xz` y bloque de 1 MB.
15. **Preparación de cargadores de arranque:** Configura el catálogo El Torito, ISOLINUX para BIOS y la partición EFI FAT con GRUB2 para UEFI.
16. **Generación de la ISO con Xorriso:** Produce la imagen ISO híbrida final en `output/NOXEnOS.iso` y calcula su suma de comprobación SHA-256.

---

## 4. Verificación del resultado

Tras finalizar la compilación, ejecuta:
```bash
bash scripts/verify-iso.sh output/NOXEnOS.iso
```
Este script validará:
- Que el archivo existe y supera los 1,5 GB (tamaño habitual de un escritorio completo con LibreOffice).
- Que la suma SHA-256 coincide exactamente con `output/NOXEnOS.iso.sha256`.
- Que la estructura interna contiene los archivos esenciales `/casper/filesystem.squashfs`, `/casper/vmlinuz`, `/casper/initrd`, `/boot/grub/grub.cfg` y el sector de arranque EFI.
