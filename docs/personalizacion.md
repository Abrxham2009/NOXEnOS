# Guía de Personalización y Experiencia de Usuario de NOXEnOS

NOXEnOS Linux ofrece un entorno de escritorio pulido, coherente y sumamente maleable. Este documento explica cómo personalizar todos los aspectos visuales, desde los temas y fondos hasta el comportamiento del dock y los perfiles de rendimiento gráfico.

---

## 1. Filosofía de diseño: macOS con identidad propia

La interfaz de NOXEnOS está concebida bajo tres principios:
1. **Flujo de trabajo limpio y despejado:** Separación funcional entre la barra superior (menús, estado global, hora y controles) y el dock inferior centrado (acceso directo a aplicaciones de uso frecuente).
2. **Identidad tecnológica futurista:** Tonos oscuros profundos combinados con degradados cian/violeta neón y tipografía moderna y nítida.
3. **Ergonomía de ventanas:** Controles de ventana situados en la esquina superior izquierda (Cerrar, Minimizar, Maximizar), facilitando un movimiento natural del ratón desde la barra de menús superior.

---

## 2. Herramienta central: `noxo-control`

Para facilitar la personalización sin obligar al usuario a editar archivos de configuración manualmente, NOXEnOS incluye la utilidad **`noxo-control`**, accesible tanto desde la terminal como con interfaz gráfica.

### Lanzar la interfaz gráfica:
- Haz doble clic en el acceso directo del escritorio **«Personalización NOXEnOS»**.
- O ejecuta en la terminal / lanzador:
  ```bash
  noxo-control gui
  ```

### Comandos directos por terminal:
```bash
# Cambiar entre modo oscuro y claro
noxo-control theme dark
noxo-control theme light

# Cambiar fondo de pantalla a uno de los preestablecidos
noxo-control wallpaper dark
noxo-control wallpaper abstract
noxo-control wallpaper neon
noxo-control wallpaper light
noxo-control wallpaper ultrawide

# Cambiar tamaño de los iconos del dock (ej: 48, 56, 64 píxeles)
noxo-control dock size 64

# Activar o desactivar la ocultación automática del dock
noxo-control dock autohide on
noxo-control dock autohide off

# Cambiar perfil de rendimiento gráfico
noxo-control mode ultra     # Activa todos los efectos, desenfoques y animaciones
noxo-control mode balanced  # Efectos estándar equilibrados
noxo-control mode low       # Desactiva blur y animaciones pesadas para ordenadores modestos
```

---

## 3. Colección de Fondos de Pantalla Oficiales

Todos los fondos de pantalla se encuentran almacenados en alta resolución en `/usr/share/wallpapers/NOXEnOS/`:

1. **`noxenos-dark-futuristic.png` (Predeterminado 4K - 3840x2160):**  
   Fondo de pizarra espacial profunda con resplandor celestial en cian eléctrico y violeta, sutil polvo estelar y el emblema 3D de NOXEnOS centrado.
2. **`noxenos-abstract-minimal.png` (4K - 3840x2160):**  
   Composición arquitectónica moderna con ondas oscuras fluidas, panel de cristal translúcido esmerilado y líneas de acento de alta tecnología.
3. **`noxenos-neon-gradient.png` (4K - 3840x2160):**  
   Degradado vibrante estilo *mesh gradient* que transiciona de azul cian eléctrico a violeta puro, ideal para setups modernos y pantallas OLED.
4. **`noxenos-light-pure.png` (4K - 3840x2160):**  
   Variante en modo claro con estética de cristal blanco/plateado puro, iluminación ambiental sutil y el emblema de NOXEnOS en acabado titanio oscuro con sombra suave.
5. **`noxenos-ultrawide.png` (Panorámico 21:9 - 3440x1440):**  
   Diseñado específicamente para monitores panorámicos y ultrawide, con iluminación horizontal amplia y atmósfera cinematográfica.

---

## 4. Personalización del Dock (Plank)

El dock está gobernado por el archivo de configuración:
`~/.config/plank/dock1/settings`

### Ajustar el tamaño del zoom (magnificación):
- Por defecto, los iconos se aumentan al **150%** de su tamaño base al pasar el ratón por encima.
- Para aumentar o disminuir el factor de aumento, edita la clave `ZoomPercent`:
  - `ZoomPercent=130` (Aumento sutil)
  - `ZoomPercent=180` (Aumento pronunciado estilo macOS)

### Añadir aplicaciones al dock:
1. Abre el gestor de archivos **Dolphin** y navega a `/usr/share/applications/`.
2. Arrastra el archivo `.desktop` del programa deseado directamente sobre el dock.
3. El nuevo lanzador se anclará automáticamente.

### Eliminar aplicaciones del dock:
1. Mantén presionada la tecla `Ctrl`.
2. Haz clic derecho sobre el icono en el dock y selecciona **«Desanclar del dock»** (o arrastra el icono hacia el escritorio hasta que aparezca el icono de disipación).

---

## 5. Personalización de la Barra Superior y Menú Global

La barra superior utiliza componentes nativos de **KDE Plasma**:
- **Menú Global:** Para que las aplicaciones muestren su menú en la barra superior en lugar de dentro de su propia ventana, NOXEnOS incluye el módulo `appmenu-gtk-module` y el widget `org.kde.plasma.appmenu`. Si deseas que alguna aplicación vuelva a mostrar la barra de menús tradicional, puedes pulsar `Ctrl + M` dentro de la propia aplicación (como en Dolphin o Konsole).
- **Reloj digital:** Puedes personalizar el formato de hora abriendo *Preferencias del Sistema* → *Fecha y hora* o haciendo clic derecho sobre el reloj en la barra superior y seleccionando *Configurar Reloj digital*.

---

## 6. Decoración de Ventanas y Efectos KWin

- **Botones de ventana:** La posición predeterminada es `XIA` (Cerrar, Minimizar, Maximizar) a la izquierda. Si prefieres la disposición clásica de Linux/Windows a la derecha, abre *Preferencias del Sistema* → *Apariencia* → *Decoración de ventanas* → *Pestaña Botones del título* y arrastra los botones a tu gusto.
- **Desenfoque translúcido (*Blur*):** KWin aplica un filtro de desenfoque de fondo Gaussiano en el dock, menús contextuales y paneles. Puedes ajustar la intensidad o el ruido abriendo *Efectos de escritorio* en Ajustes del Sistema.
- **Animación de minimizar:** NOXEnOS viene con el efecto *Sheet/Magic Lamp* (Lámpara mágica) configurado para imitar la absorción fluida de ventanas hacia el dock.
