# Guía de Instalación y Uso de NOXEnOS Linux

Este manual describe el proceso de arranque en modo Live y la instalación permanente en disco de **NOXEnOS Linux 2026.1 LTS**.

---

## 1. Preparación del medio de instalación (Memoria USB)

Para instalar o probar NOXEnOS en un ordenador real o máquina virtual, necesitas transferir la imagen `output/NOXEnOS.iso` a una memoria USB de al menos **4 GB**.

### Opción A: Usando Ventoy (Método más recomendado)
1. Descarga e instala [Ventoy](https://www.ventoy.net) en tu memoria USB.
2. Copia directamente el archivo `NOXEnOS.iso` a la partición de datos del USB.
3. Al encender el ordenador, arranca desde el USB y selecciona NOXEnOS en la lista.

### Opción B: Usando Rufus (En Windows)
1. Conecta tu memoria USB y abre **Rufus**.
2. En *Elección de arranque*, selecciona `output/NOXEnOS.iso`.
3. Esquema de partición: **GPT** (para equipos UEFI) o **MBR** (para equipos antiguos con BIOS).
4. Si Rufus pregunta por el modo de escritura, selecciona **Modo imagen DD** para asegurar la compatibilidad total del cargador híbrido.
5. Pulsa *Empezar*.

### Opción C: Usando el comando `dd` (En Linux / macOS)
```bash
sudo dd if=output/NOXEnOS.iso of=/dev/sdX bs=4M status=progress oflag=sync
```
*(Reemplaza `/dev/sdX` por el identificador exacto de tu memoria USB, no una partición como `/dev/sdX1`)*.

---

## 2. Ajustes previos en la BIOS / UEFI del equipo

Antes de arrancar desde el USB:
1. Conecta la memoria USB con el ordenador apagado.
2. Enciende el equipo y pulsa la tecla del menú de arranque (`F12`, `F11`, `F8`, `F10` o `Esc` según el fabricante).
3. Si el equipo no detecta el USB o muestra error de firma:
   - Accede a la configuración UEFI (`F2` o `Del`).
   - Asegúrate de que el controlador de disco está en modo **AHCI** (no RAID / Intel RST).
   - Desactiva el inicio rápido de Windows (*Fast Boot*).
   - Si tu placa base tiene un Secure Boot estricto sin soporte de claves de terceros, desactiva temporalmente el *Secure Boot*.

---

## 3. Menú de arranque de la ISO

Al iniciar la máquina con la ISO de NOXEnOS, aparecerá el menú interactivo con las siguientes opciones:

1. **Probar NOXEnOS Linux (Modo Live):**  
   Carga el sistema operativo completamente en la memoria RAM. Te permite navegar, probar LibreOffice, conectar a Wi-Fi y verificar la compatibilidad de tu hardware sin alterar ningún archivo de tus discos duros.
2. **Instalar NOXEnOS Linux directamente:**  
   Arranca el entorno de escritorio e inicia inmediatamente el asistente de instalación **Calamares**.
3. **Probar NOXEnOS (Gráficos Seguros):**  
   Arranca con el parámetro de kernel `nomodeset`. Úsalo si tu pantalla se queda en negro o si tienes una tarjeta gráfica dedicada que requiera controladores básicos durante el primer arranque.
4. **Comprobar integridad del medio:**  
   Verifica que la memoria USB no tenga sectores dañados.
5. **Iniciar desde el disco duro local / Reiniciar:**  
   Vuelve al arranque habitual de tu ordenador.

---

## 4. Proceso de instalación guiado con Calamares

Una vez en el escritorio Live, puedes hacer doble clic en el icono del escritorio **«Instalar NOXEnOS Linux»** para abrir el instalador oficial.

### Paso 1: Bienvenida e idioma
- Selecciona tu idioma (predeterminado: **Español**).
- El instalador comprobará que el equipo cumple los requisitos:
  - Al menos 2 GB de memoria RAM.
  - Al menos 20 GB de espacio libre en disco.
  - Conexión a la corriente (en ordenadores portátiles).

### Paso 2: Ubicación y zona horaria
- Selecciona tu región geográfica (predeterminado: **Europa/Madrid**).
- La hora y el formato numérico se sincronizarán automáticamente.

### Paso 3: Distribución del teclado
- Selecciona tu teclado (predeterminado: **Español**).
- Puedes utilizar el cuadro de pruebas inferior para verificar caracteres como `ñ`, tildes, `@` y llaves `{}`.

### Paso 4: Particionado del disco
Calamares ofrece dos métodos:
- **Borrar disco (Instalación limpia):**  
  Elimina todo el contenido del disco seleccionado y crea automáticamente el esquema óptimo (partición EFI de 512 MB, partición raíz en ext4 y archivo de intercambio *swapfile*).
  > ⚠️ **Advertencia de seguridad:** Este proceso borrará los datos del disco seleccionado. Asegúrate de tener copias de seguridad de tus archivos importantes.
- **Particionado manual (Avanzado / Arranque dual):**  
  Te permite seleccionar una partición existente para instalar NOXEnOS junto a otro sistema operativo (como Windows o Linux) sin tocar otras particiones.
  - Punto de montaje `/boot/efi`: Partición FAT32 de 512 MB con indicador `boot` y `esp`.
  - Punto de montaje `/`: Partición `ext4` o `btrfs` con al menos 20 GB de espacio.

### Paso 5: Creación de usuario y seguridad
- **Nombre completo:** Tu nombre o alias.
- **Nombre de usuario:** Nombre técnico para tu carpeta personal (`/home/usuario`).
- **Nombre del equipo:** Identificador de red del ordenador.
- **Contraseña:** Contraseña segura para inicio de sesión y privilegios `sudo`.
- Puedes marcar si deseas iniciar sesión automáticamente o solicitar la contraseña cada vez.

### Paso 6: Resumen y confirmación
Calamares mostrará un resumen detallado de todos los cambios que se van a efectuar. Hasta este momento no se ha tocado ningún dato en tu disco. Pulsa **«Instalar ahora»** para iniciar el copiado.

### Paso 7: Finalización y primer reinicio
El proceso tardará entre 5 y 10 minutos dependiendo de la velocidad de tu disco SSD/NVMe. Al terminar:
1. Marca la casilla **«Reiniciar ahora»** y pulsa **Hecho**.
2. Cuando la pantalla lo indique, retira la memoria USB y presiona `Enter`.

---

## 5. Primer arranque en NOXEnOS

Al iniciar tu nuevo sistema instalado:
- Se presentará la pantalla de inicio de sesión **SDDM** con el fondo oficial y la identidad NOXEnOS.
- Una vez introducida tu contraseña, el escritorio se desplegará con el tema oscuro predeterminado, la barra superior integrada y el dock con animación fluida.
- Se abrirá automáticamente el asistente de bienvenida **`noxo-welcome`**, permitiéndote abrir la suite **LibreOffice**, acceder a la **NOXEnOS Store** o personalizar temas y fondos.
