#!/bin/bash

# Script de configuración para i3, picom y herramientas relacionadas
# Solo configuraciones - NO instala paquetes
set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }

print_section "Configurando .xinitrc"

# .xinitrc básico
cat > ~/.xinitrc << 'EOF'
#!/bin/sh
# Configurar teclado permanentemente
setxkbmap latam &
# Configurar layout de consola virtual también
sudo localectl set-keymap la-latin1 &
# Restaurar tema pywal
(cat ~/.cache/wal/sequences &) 2>/dev/null
# Compositor con bordes redondeados
picom -b &
# Gestor de red
nm-applet &
# Bluetooth
blueman-applet &
# Filtro de luz azul
#redshift -l 19.4:-99.1 &
# Polybar
polybar main &
# Wallpaper
nitrogen --restore &
# i3
exec i3
EOF

print_section "Configurando i3"

# Configuración básica de i3
mkdir -p ~/.config/i3
if [ ! -f ~/.config/i3/config ]; then
    cp /etc/i3/config ~/.config/i3/config
fi

# Agregar configuraciones modernas al config de i3
cat >> ~/.config/i3/config << 'EOF'

# Configuraciones adicionales modernas
# Variables de colores pywal
set_from_resource $fg i3wm.color7 #f0f0f0
set_from_resource $bg i3wm.color2 #f0f0f0
set_from_resource $accent i3wm.color1 #f0f0f0

# Esquema de colores
# class                 border  backgr. text indicator child_border
client.focused          $accent $accent $bg  $accent   $accent
client.focused_inactive $bg     $bg     $fg  $bg       $bg
client.unfocused        $bg     $bg     $fg  $bg       $bg
client.urgent           #ff0000 #ff0000 $fg  #ff0000   #ff0000

# Gaps y bordes
gaps inner 10
gaps outer 5
for_window [class=".*"] border pixel 2
smart_gaps on
smart_borders on

# Wallpaper con nitrogen
exec --no-startup-id nitrogen --restore

# Screenshots
bindsym Print exec --no-startup-id maim ~/Pictures/screenshot-$(date +%s).png
bindsym $mod+Print exec --no-startup-id maim -s ~/Pictures/screenshot-$(date +%s).png

# Control de volumen
bindsym XF86AudioRaiseVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym XF86AudioLowerVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -5%
bindsym XF86AudioMute exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle

# Brillo (si tu laptop lo soporta)
bindsym XF86MonBrightnessUp exec --no-startup-id xbacklight -inc 10
bindsym XF86MonBrightnessDown exec --no-startup-id xbacklight -dec 10

# Rofi en lugar de dmenu
bindsym $mod+d exec rofi -show run

# Polybar en lugar de i3bar
bar {
    mode invisible
}

# Keybind para cambiar wallpaper y generar tema
bindsym $mod+w exec --no-startup-id wal -i ~/Pictures/wallpapers/ && nitrogen --set-wallpaper $(cat ~/.cache/wal/wal) && i3-msg restart
EOF

print_section "Configurando Polybar"

# Configuración mejorada de polybar
mkdir -p ~/.config/polybar
cat > ~/.config/polybar/config.ini << 'EOF'
[colors]
include-file = ~/.cache/wal/colors-polybar

[bar/main]
width = 100%
height = 30
radius = 15
fixed-center = true
top = true

background = ${colors.background}
foreground = ${colors.foreground}

padding-left = 2
padding-right = 2
module-margin-left = 1
module-margin-right = 1

font-0 = "JetBrains Mono:size=10;2"
font-1 = "Font Awesome 6 Free Solid:size=10;2"
font-2 = "Font Awesome 6 Brands:size=10;2"

modules-left = i3
modules-center = 
modules-right = pulseaudio battery date

override-redirect = false
wm-restack = i3

[module/i3]
type = internal/i3
format = <label-state> <label-mode>
index-sort = true
wrapping-scroll = false

label-mode-padding = 2
label-mode-foreground = ${colors.foreground}
label-mode-background = ${colors.color1}

label-focused = %index%
label-focused-background = ${colors.color1}
label-focused-foreground = ${colors.background}
label-focused-padding = 2
label-focused-radius = 5

label-unfocused = %index%
label-unfocused-padding = 2

label-visible = %index%
label-visible-background = ${colors.color2}
label-visible-padding = 2

label-urgent = %index%!
label-urgent-background = ${colors.color3}
label-urgent-padding = 2

[module/date]
type = internal/date
interval = 5
date = %d/%m
time = %H:%M
format-prefix = " "
format-prefix-foreground = ${colors.color1}
label = %date% %time%

[module/battery]
type = internal/battery
battery = BAT0
adapter = ADP1
full-at = 98

format-charging = <animation-charging> <label-charging>
format-charging-foreground = ${colors.color2}
format-discharging = <ramp-capacity> <label-discharging>
format-discharging-foreground = ${colors.foreground}
format-full-prefix = " "
format-full-prefix-foreground = ${colors.color2}

ramp-capacity-0 = 
ramp-capacity-1 = 
ramp-capacity-2 = 
ramp-capacity-3 = 
ramp-capacity-4 = 

animation-charging-0 = 
animation-charging-1 = 
animation-charging-2 = 
animation-charging-3 = 
animation-charging-4 = 
animation-charging-framerate = 750

[module/pulseaudio]
type = internal/pulseaudio

format-volume = <ramp-volume> <label-volume>
label-volume = %percentage%%
label-volume-foreground = ${colors.foreground}

label-muted =  muted
label-muted-foreground = ${colors.color3}

ramp-volume-0 = 
ramp-volume-1 = 
ramp-volume-2 = 

click-right = pavucontrol
EOF

# Script de polybar
cat > ~/.config/polybar/launch.sh << 'EOF'
#!/bin/bash
killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done
polybar main &
EOF
chmod +x ~/.config/polybar/launch.sh

print_section "Configurando Picom"

# Configuración de picom con bordes redondeados
mkdir -p ~/.config/picom
cat > ~/.config/picom/picom.conf << 'EOF'
# Configuración de picom con bordes redondeados
backend = "glx";
vsync = true;

# Sombras
shadow = true;
shadow-radius = 12;
shadow-offset-x = -12;
shadow-offset-y = -12;
shadow-opacity = 0.3;

# Transparencia
inactive-opacity = 0.95;
active-opacity = 1.0;
frame-opacity = 1.0;

# Bordes redondeados
corner-radius = 10;
rounded-corners-exclude = [
    "window_type = 'dock'",
    "window_type = 'desktop'",
    "class_g = 'Polybar'",
];

# Fading
fading = true;
fade-delta = 5;
fade-in-step = 0.03;
fade-out-step = 0.03;

# Blur (comentado para rendimiento)
# blur: {
#   method = "dual_kawase";
#   strength = 3;
# };

wintypes: {
  tooltip = { fade = true; shadow = true; opacity = 0.9; focus = true; full-shadow = false; };
  dock = { shadow = false; clip-shadow-above = true; }
  dnd = { shadow = false; }
  popup_menu = { opacity = 0.95; }
  dropdown_menu = { opacity = 0.95; }
};
EOF

print_section "Configurando Rofi"

mkdir -p ~/.config/rofi
cat > ~/.config/rofi/config.rasi << 'EOF'
@import "~/.cache/wal/colors-rofi-dark"

configuration {
    modi: "drun,run";
    show-icons: true;
    icon-theme: "Papirus-Dark";
    font: "JetBrains Mono 12";
    display-drun: " Apps";
    display-run: " Run";
    display-window: " Windows";
}

window {
    transparency: "real";
    border-radius: 10px;
}

listview {
    border-radius: 5px;
}

element {
    border-radius: 5px;
}
EOF

print_section "Configurando wpgtk"

mkdir -p ~/.config/wpg
cat > ~/.config/wpg/wpg.conf << 'EOF'
{
    "gtk": true,
    "sublime": false,
    "auto": false,
    "light_theme": false,
    "editor": "vim",
    "execute_cmd": true,
    "samples": 16,
    "alpha": "100",
    "smart_sort": true,
    "backend": "wal",
    "recolor_icons": false
}
EOF

print_section "Configurando gestos de trackpad"

mkdir -p ~/.config
cat > ~/.config/libinput-gestures.conf << 'EOF'
# Gestos básicos para trackpad
gesture swipe up 3 xdotool key super+Up
gesture swipe down 3 xdotool key super+Down
gesture swipe left 3 xdotool key super+Left
gesture swipe right 3 xdotool key super+Right
gesture pinch in 2 xdotool key ctrl+minus
gesture pinch out 2 xdotool key ctrl+plus
EOF

print_section "Configuración de teclado"

print_status "Configurando layout de teclado la-latin1..."
# Para X11
echo 'Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "latam"
    Option "XkbModel" "pc105"
EndSection' | sudo tee /etc/X11/xorg.conf.d/00-keyboard.conf

# Para consola virtual (TTY)
sudo localectl set-keymap la-latin1
sudo localectl set-x11-keymap latam

print_section "Creando directorios necesarios"

# Crear directorios básicos
mkdir -p ~/Pictures ~/Downloads ~/Documents ~/Pictures/wallpapers

print_section "Script para cambiar wallpaper"

cat > ~/change_wallpaper.sh << 'EOF'
#!/bin/bash
# Script para cambiar wallpaper y generar tema
WALLPAPER_DIR="$HOME/Pictures/wallpapers"

if [ -z "$1" ]; then
    # Seleccionar wallpaper aleatorio si no se especifica uno
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | shuf -n 1)
else
    WALLPAPER="$1"
fi

if [ -f "$WALLPAPER" ]; then
    # Generar tema con pywal
    wal -i "$WALLPAPER" -n
    
    # Configurar wallpaper con nitrogen
    nitrogen --set-wallpaper "$WALLPAPER" --save
    
    # Reiniciar polybar para aplicar nuevos colores
    ~/.config/polybar/launch.sh
    
    # Aplicar colores a aplicaciones GTK
    wpg -s "$WALLPAPER" -n
    
    echo "Tema aplicado con wallpaper: $WALLPAPER"
else
    echo "Error: No se encontró wallpaper válido"
    echo "Coloca algunas imágenes en ~/Pictures/wallpapers/"
fi
EOF
chmod +x ~/change_wallpaper.sh

print_section "¡Configuración completada!"

print_status "Configuraciones aplicadas:"
echo "  • i3 con gaps, bordes y esquemas de color dinámicos"
echo "  • Polybar con iconos y diseño moderno"
echo "  • Picom con bordes redondeados y transparencias"
echo "  • Rofi con tema que sigue el wallpaper"
echo "  • wpgtk para temas GTK automáticos"
echo "  • Gestos de trackpad configurados"
echo "  • .xinitrc configurado para auto-inicio"
echo ""
print_status "Comandos útiles:"
echo "  • ./change_wallpaper.sh - Cambiar wallpaper y tema"
echo "  • Super+w - Cambiar wallpaper aleatorio (en i3)"
echo "  • Super+d - Abrir rofi con tema dinámico"
echo ""
print_warning "Para que funcione completamente:"
echo "  1. Agrega wallpapers a ~/Pictures/wallpapers/"
echo "  2. Ejecuta ./change_wallpaper.sh para configurar tema inicial"
echo "  3. Reinicia i3 con Super+Shift+r o reinicia X11"
echo "  4. Si tienes libinput-gestures instalado, ejecuta:"
echo "     libinput-gestures-setup autostart"
echo "     libinput-gestures-setup start"

print_status "¡Listo! Todas las configuraciones han sido aplicadas."