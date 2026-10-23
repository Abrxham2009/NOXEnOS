# Solución de Problemas y Preguntas Frecuentes (FAQ)

Esta guía recopila soluciones a las incidencias más comunes durante la compilación, el arranque, la instalación y el uso de **NOXEnOS Linux**.

---

## 1. Problemas durante la compilación de la ISO

### Error: `debootstrap: command not found` o herramientas faltantes
**Causa:** No se han instalado las herramientas de construcción en el host de Linux.  
**Solución:** Ejecuta el verificador y el comando de instalación:
```bash
sudo bash scripts/check-dependencies.sh
sudo apt update && sudo apt install -y debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools dosfstools isolinux syslinux-common
```

---

### Error: `No space left on device` durante `mksquashfs`
**Causa:** La compresión del sistema de archivos requiere al menos 12 a 15 GB de espacio libre en disco para los archivos temporales y la imagen squashfs final.  
**Solución:** Comprueba el espacio disponible con `df -h .`. Si estás compilando dentro de una máquina virtual o contenedor Docker, aumenta el tamaño del disco asignado.

---

### Error: `device is busy` al desmontar directorios en chroot
**Causa:** Un proceso interno de chroot o un demonio se quedó en segundo plano bloqueando `/dev` o `/proc`.  
**Solución:** Fuerza el desmontaje perezoso de los puntos de montaje antes de reintentar:
```bash
sudo umount -lf build_work/rootfs/dev/pts 2>/dev/null || true
sudo umount -lf build_work/rootfs/dev 2>/dev/null || true
sudo umount -lf build_work/rootfs/proc 2>/dev/null || true
sudo umount -lf build_work/rootfs/sys 2>/dev/null || true
sudo umount -lf build_work/rootfs/run 2>/dev/null || true
```

---

## 2. Problemas durante el arranque en vivo (Live USB)

### Pantalla en negro tras el menú de GRUB
**Causa:** Incompatibilidad temporal del controlador gráfico con modos KMS (*Kernel Mode Setting*) en ciertas tarjetas gráficas Nvidia modernas o sistemas híbridos.  
**Solución:**
1. En el menú de arranque de la ISO, selecciona la tercera opción:  
   **«Probar NOXEnOS (Gráficos Seguros / Modo Compatibilidad)»**.
2. Esta opción añade el parámetro de kernel `nomodeset`, permitiendo iniciar el escritorio mediante el búfer de vídeo genérico VESA/GOP hasta que el sistema esté instalado y se descargue el controlador privativo mediante el asistente de controladores de Ubuntu.

---

### Error: `Security Boot Violation` / Firma no válida al arrancar
**Causa:** Algunas placas base UEFI tienen activada la directiva de *Secure Boot* en modo estricto de solo Microsoft.  
**Solución:**
1. Entra a la BIOS/UEFI de tu ordenador (pulsando `F2`, `F10` o `Del` al encender).
2. Localiza la sección **Security** o **Boot**.
3. Cambia la opción **Secure Boot** a **Disabled** (Desactivado).
4. Guarda los cambios con `F10` y reinicia.

---

### La memoria USB no aparece en el menú de arranque del equipo
**Causa:** El medio fue grabado en modo ISO estándar o la tabla de particiones no coincide con el modo de firmware del equipo (UEFI vs Legacy BIOS).  
**Solución:**
- Graba la ISO usando **Ventoy** (soporta ambos modos de forma automática).
- O en **Rufus**, asegúrate de seleccionar **Modo imagen DD** cuando aparezca la ventana emergente de confirmación.

---

## 3. Problemas en Máquinas Virtuales (VirtualBox / VMware)

### El dock se ve negro o sin transparencias
**Causa:** La máquina virtual no tiene habilitada la aceleración 3D por hardware, por lo que el compositor KWin no puede aplicar desenfoque Gaussiano.  
**Solución en VirtualBox:**
1. Apaga la máquina virtual.
2. Abre *Configuración* → *Pantalla*.
3. Controlador gráfico: selecciona **VMSVGA**.
4. Memoria de vídeo: asígnale al menos **128 MB**.
5. Marca la casilla **«Habilitar aceleración 3D»**.
6. Inicia de nuevo la máquina virtual.

---

### La resolución de pantalla es fija y pequeña (ej. 800x600 o 1024x768)
**Causa:** Faltan las adiciones de invitado (*Guest Additions*).  
**Solución:** NOXEnOS incluye por defecto los controladores `virtualbox-guest-utils` y `open-vm-tools`. Para ajustar la resolución, abre *Preferencias del Sistema* → *Pantalla y monitor* y selecciona la resolución de tu monitor, o maximiza la ventana de VirtualBox con el menú *Ver* → *Pantalla con cambio de tamaño automático*.

---

## 4. Problemas durante la instalación (Calamares)

### Error en el particionado manual: `No mount point for /boot/efi`
**Causa:** En sistemas UEFI, se requiere obligatoriamente una partición de arranque EFI.  
**Solución:**
1. En el paso de particionado manual de Calamares, selecciona o crea una partición de **512 MB**.
2. Sistema de archivos: **FAT32**.
3. Punto de montaje: `/boot/efi`.
4. Indicadores (*flags*): marca **boot** y **esp**.

---

### La instalación tarda mucho en el 85% - 90%
**Causa:** El sistema está ejecutando `update-initramfs` y configurando el cargador GRUB en disco. En discos duros mecánicos (HDD) o memorias USB 2.0 lentas, este proceso puede demorarse varios minutos.  
**Solución:** No apagues el equipo. Permite que el instalador finalice las operaciones de sincronización de caché en disco (`sync`).

---

## 5. Problemas en el escritorio

### El dock Plank no aparece al iniciar sesión
**Causa:** El servicio se cerró de forma inesperada o no se ejecutó el archivo de autoinicio.  
**Solución:**
- Abre una terminal (o pulsa `Alt + F2`) y escribe `plank`.
- Para comprobar que el autoinicio está habilitado:
  ```bash
  cat ~/.config/autostart/plank.desktop
  ```
  Debe contener `Exec=plank` y `Hidden=false`.

---

### El audio no se escucha
**Solución:**
1. Haz clic en el icono del altavoz en la barra superior derecha.
2. Asegúrate de que la salida de audio no esté silenciada (*Mute*).
3. Si tienes múltiples salidas (altavoces, HDMI, auriculares), abre *Ajustes del Sistema* → *Audio* y selecciona el dispositivo de salida predeterminado en la pestaña *Dispositivos*.
4. Para reiniciar el servidor PipeWire:
   ```bash
   systemctl --user restart pipewire pipewire-pulse wireplumber
   ```
