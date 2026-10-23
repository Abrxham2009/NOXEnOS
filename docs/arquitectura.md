# Arquitectura Técnica de NOXEnOS Linux

Este documento describe la arquitectura interna, la pila de componentes, el subsistema Live y las decisiones técnicas de diseño adoptadas en **NOXEnOS Linux 2026.1 LTS**.

---

## 1. Visión general de la pila de capas

```text
┌────────────────────────────────────────────────────────┐
│            EXPERIENCIA DE USUARIO (UX / UI)            │
│  Barra superior (Menú Global) │ Dock con zoom magnético│
│  Suite LibreOffice │ Firefox │ Dolphin │ Discover      │
├────────────────────────────────────────────────────────┤
│             ENTORNO DE ESCRITORIO (KDE)                │
│       KDE Plasma 5.27 LTS │ KWin Compositor            │
│       Tema NOXEnOS Dark / Light │ Look and Feel        │
├────────────────────────────────────────────────────────┤
│           SERVICIOS DEL SISTEMA Y MULTIMEDIA           │
│   systemd v255 │ PipeWire + WirePlumber │ NetworkMgr   │
│   BlueZ (Bluetooth) │ UFW Firewall │ ZRAM swap (zstd)  │
├────────────────────────────────────────────────────────┤
│             NÚCLEO Y CONTROLADORES (KERNEL)            │
│       Linux Kernel 6.8+ Generic HWE │ Linux Firmware   │
│       Mesa DRM / KMS │ Soporte UEFI GPT y BIOS MBR     │
├────────────────────────────────────────────────────────┤
│             DISTRIBUCIÓN BASE Y EMPAQUETADO            │
│       Ubuntu 24.04 LTS (Noble Numbat) │ APT PackageKit │
└────────────────────────────────────────────────────────┘
```

---

## 2. Base técnica y justificación de selección

### 2.1 Distribución base: Ubuntu 24.04 LTS (Noble Numbat)
Se ha seleccionado **Ubuntu 24.04 LTS** como cimiento por las siguientes razones:
- **Ciclo de soporte:** Cuenta con soporte a largo plazo de 5 años con actualizaciones de seguridad continuas y repositorios mantenidos profesionalmente.
- **Compatibilidad de hardware:** Incorpora la pila de kernel moderna (Linux 6.8+), soporte para CPUs Intel Core Ultra, AMD Ryzen 7000/8000, gráficas Intel Iris Xe/Arc, AMD Radeon RDNA3 y controladores privativos Nvidia.
- **Subsistema Casper maduro:** El initramfs de arranque en vivo `casper` de Ubuntu es el estándar industrial para arranque en red, USB y medios ópticos, con detección automática de hardware y montaje dinámico con OverlayFS.
- **Ecosistema APT masivo:** Acceso a miles de paquetes estables sin fragmentación de dependencias.

---

## 3. Subsistema de visualización y entorno gráfico

### 3.1 KDE Plasma 5.27.11 LTS
KDE Plasma fue seleccionado como entorno principal por:
- **Rendimiento superior:** Consumo en reposo extremadamente bajo (~550 MB a 650 MB de RAM), menor que GNOME y con latencias de compositor KWin de nivel milimétrico.
- **Modularidad total:** Capacidad de desacoplar los paneles para crear una barra superior nativa con menú global y desacoplar el gestor de tareas hacia un dock inferior.
- **Soporte Wayland y X11:** Compatibilidad completa con sesiones modernas en Wayland y respaldo estable en X11 para equipos con aceleración heredada.

### 3.2 El Dock y el efecto de aumento parabólico
Para satisfacer el requisito de un dock con **animación real de aumento al pasar el ratón** (magnificación progresiva tipo macOS):
- Se integra **Plank** con aceleración por hardware.
- Se ha diseñado el tema exclusivo `NOXEnOS-DarkGlass` (`config/desktop/plank/dock.theme`) que ofrece esquinas redondeadas (radio 16px), fondo translúcido oscuro (`#0e121d` a 82% de opacidad) y borde con resplandor en cian eléctrico (`#00d2ff`).
- La configuración activa `ZoomEnabled=true` y `ZoomPercent=150` con auto-ocultación inteligente (`HideMode=1`), garantizando 60 fps constantes.
- Como alternativa para entornos 100% Wayland nativos, se proporciona el diseño de panel flotante de Plasma.

### 3.3 Barra superior y Menú Global
- Panel de 28 px de altura anclado al borde superior.
- Integra el widget `org.kde.plasma.appmenu`, interceptando la barra de menús de las aplicaciones GTK y Qt para renderizarlas en la barra superior.
- Icono oficial de NOXEnOS en la esquina izquierda que activa el lanzador Kickoff.
- Bandeja de sistema con controles rápidos para volumen, redes, batería, fecha/hora y notificaciones.

---

## 4. Subsistema de audio y multimedia

- **Servidor de audio:** **PipeWire** con gestor de sesiones **WirePlumber**.
- Reemplaza por completo a PulseAudio nativo mediante capas de compatibilidad transparentes (`pipewire-pulse`).
- Ofrece latencia ultra baja, soporte para dispositivos de audio Bluetooth con códecs de alta fidelidad (AAC, LDAC, aptX) y enrutamiento gráfico de flujos.

---

## 5. Proceso de construcción y arranque Live

### 5.1 Arquitectura del medio Live (Casper + Squashfs)
1. El sistema raíz de NOXEnOS se empaqueta en una imagen comprimida de solo lectura `casper/filesystem.squashfs` utilizando el algoritmo **XZ** con bloques de 1 MB (`-b 1048576`).
2. Durante el arranque en vivo, el kernel carga el initramfs `casper`, localiza el medio USB o CD, monta el squashfs como bucle (`loop`) de solo lectura y crea una capa de escritura en memoria RAM mediante **OverlayFS**.
3. Esto permite que el usuario pruebe el sistema, modifique archivos, instale programas de prueba y navegue sin tocar el almacenamiento permanente.

### 5.2 Estructura de arranque híbrido (UEFI + BIOS)
La ISO generada por `scripts/build-iso.sh` es una **imagen ISO-9660 híbrida arrancable** compatible con:
- **UEFI Moderno (64 bits):** Imagen FAT `boot/grub/efi.img` con el cargador `BOOTX64.EFI` y menú GRUB2.
- **Legacy BIOS (MBR):** Sector MBR con cargador El Torito e ISOLINUX (`isolinux.bin`).
- Soporte para Secure Boot firmado mediante shim y certificados de distribución estándar.

---

## 6. Instalador del sistema: Calamares

Se ha elegido **Calamares 3.3+** como instalador oficial:
- **Nativo Qt/C++:** Se integra orgánicamente con el aspecto visual de KDE Plasma sin dependencias pesadas de GTK.
- **Seguridad en particionado:** Utiliza `kpmcore` para particionado guiado o manual con advertencias claras antes de escribir la tabla de particiones (soporta GPT y MBR, sistemas de archivos ext4, btrfs con subvolúmenes y xfs).
- **Independencia de conexión:** No requiere conexión activa a Internet para instalar el sistema base, ya que todos los paquetes esenciales, LibreOffice y Firefox se descomprimen directamente desde el squashfs local de la ISO.
- **Limpieza post-instalación:** El módulo `packages.conf` elimina automáticamente los paquetes específicos de la sesión en vivo (`casper`, `calamares`) para dejar una instalación limpia.

---

## 7. Ajustes de optimización y memoria

- **ZRAM con compresión zstd:** Asigna un 50% de la memoria física como espacio de swap comprimido en RAM de alta velocidad, evitando que el sistema se congele por thrashing de disco cuando la memoria física escasea.
- **`vm.swappiness = 10`:** Evita que el kernel desaloje páginas de aplicaciones interactivas hacia el swap a menos que sea estrictamente necesario.
- **`vm.vfs_cache_pressure = 50`:** Prioriza la conservación de la caché de inodos y directorios en RAM, acelerando la navegación en Dolphin y la apertura de archivos.
- **`noxo-control mode low`:** Proporciona un modo de bajo consumo gráfico que desactiva el desenfoque (*blur*), las animaciones de lámpara mágica y reduce los efectos de ventana para equipos modestos o máquinas virtuales con gráficos limitados.
