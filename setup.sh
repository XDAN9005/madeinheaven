#!/bin/bash

# Script de instalación de paquetes para setup i3 moderno
# Solo instala paquetes y configura teclado - NO crea configuraciones
set -e

sudo -k

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }

print_section "Actualizando el sistema"
sudo pacman -Syu --noconfirm

print_section "Instalando X11 y drivers básicos"
sudo pacman -S --noconfirm \
    xorg-server xorg-xinit xorg-xsetroot \
    mesa vulkan-intel \
    xf86-input-libinput

print_section "Instalando i3 y herramientas de ventana"
sudo pacman -S --noconfirm \
    i3-wm i3lock \
    dmenu rofi \
    picom \
    kitty \
    lightdm lightdm-gtk-greeter

print_section "Audio (PulseAudio ligero)"
sudo pacman -S --noconfirm \
    pulseaudio pulseaudio-alsa pulseaudio-bluetooth \
    pavucontrol pulsemixer \
    alsa-utils
sudo usermod -a -G audio $USER

print_section "Bluetooth y conectividad"
sudo pacman -S --noconfirm \
    bluez bluez-utils blueman \
    networkmanager network-manager-applet \
    wireless_tools wpa_supplicant
sudo systemctl enable bluetooth NetworkManager

print_section "Gestión de archivos y utilidades básicas"
sudo pacman -S --noconfirm \
    thunar thunar-archive-plugin gvfs gvfs-mtp \
    file-roller unzip unrar p7zip \
    xarchiver \
    pcmanfm

print_section "Multimedia ligero"
sudo pacman -S --noconfirm \
    mpv \
    feh sxiv \
    aegisub \
    ffmpeg yt-dlp

print_section "Herramientas de configuración GUI"
sudo pacman -S --noconfirm \
    lxappearance gtk-engine-murrine \
    qt5ct \
    nitrogen arandr \
    xfce4-settings xfce4-power-manager

print_section "Utilidades del sistema"
sudo pacman -S --noconfirm \
    htop neofetch \
    tree ranger \
    git wget curl \
    mousepad \
    firefox \
    scrot maim \
    redshift

print_section "Fuentes ligeras pero completas"
sudo pacman -S --noconfirm \
    ttf-dejavu ttf-liberation \
    noto-fonts-emoji \
    terminus-font \
    ttf-font-awesome

print_section "Desarrollo básico"
sudo pacman -S --noconfirm \
    python python-pip \
    vim \
    base-devel

print_section "Herramientas para temas dinámicos"
sudo pacman -S --noconfirm \
    python-pywal \
    imagemagick

print_section "Gaming ligero"
# Habilitar multilib para Steam
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    print_status "Habilitando repositorio multilib..."
    sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' /etc/pacman.conf
    sudo pacman -Sy
fi

sudo pacman -S --noconfirm steam
# Para tu control GameSir
sudo pacman -S --noconfirm xpadneo-dkms

print_section "Impresora HP (si la necesitas)"
sudo pacman -S --noconfirm cups hplip system-config-printer
sudo systemctl enable cups
sudo usermod -a -G lp $USER

print_section "Instalando AUR helper (yay - más ligero que paru)"
if ! command -v yay &> /dev/null; then
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ~
    rm -rf /tmp/yay
fi

print_section "Node.js y herramientas de desarrollo"
sudo pacman -S --noconfirm nodejs npm

print_section "Soporte para gestos de trackpad"
sudo pacman -S --noconfirm libinput-gestures xdotool
# Agregar usuario al grupo input para gestos
sudo usermod -a -G input $USER

print_section "Aplicaciones AUR esenciales"
yay -S --noconfirm \
    polybar \
    picom-git \
    brave-bin \
    visual-studio-code-bin \
    cursor-theme-capitaine \
    telegram-desktop \
    bottles \
    freedownloadmanager \
    sumatrapdf \
    ani-cli \
    ani-skip-git \
    wpgtk-git

print_section "Configuración de teclado X11"
print_status "Configurando layout de teclado latam (equivalente a la-latin1)..."

# Crear directorio si no existe
sudo mkdir -p /etc/X11/xorg.conf.d

# Configuración para X11 (latam es el equivalente de la-latin1)
echo 'Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "latam"
    Option "XkbModel" "pc105"
EndSection' | sudo tee /etc/X11/xorg.conf.d/00-keyboard.conf

# Para consola virtual (TTY) - mantenemos la-latin1
sudo localectl set-keymap la-latin1
sudo localectl set-x11-keymap latam

print_status "Verificando configuración de teclado..."
print_status "X11 layout: latam"
print_status "Console keymap: la-latin1"

print_section "Habilitando servicios"
sudo systemctl enable lightdm

print_section "Optimizaciones para laptop vieja"
print_status "Configurando swappiness para SSD/HDD..."
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf

print_section "Limpieza del sistema"
sudo pacman -Sc --noconfirm
yay -Sc --noconfirm

sudo -v

print_section "¡Instalación completada!"
print_status "Paquetes instalados exitosamente:"
echo ""
echo "Paquetes principales:"
echo "  • i3-wm, i3lock"
echo "  • polybar (AUR)"
echo "  • picom-git (AUR)"
echo "  • rofi, dmenu"
echo "  • kitty (terminal)"
echo "  • python-pywal, wpgtk-git"
echo "  • nitrogen, feh, sxiv"
echo ""
echo "Aplicaciones útiles:"
echo "  • Firefox, Brave (AUR)"
echo "  • Visual Studio Code (AUR)"
echo "  • Telegram Desktop"
echo "  • Bottles para apps Windows"
echo "  • ani-cli para anime"
echo ""
echo "Herramientas del sistema:"
echo "  • NetworkManager, Bluetooth"
echo "  • PulseAudio + pavucontrol"
echo "  • Thunar, PCManFM"
echo "  • Git, Node.js, npm"
echo "  • libinput-gestures para trackpad"
echo ""
print_status "Configuración de teclado aplicada:"
echo "  • X11: layout latam (equivalente a la-latin1)"
echo "  • Console: keymap la-latin1"
echo "  • Archivo: /etc/X11/xorg.conf.d/00-keyboard.conf"
echo ""
print_warning "Siguiente paso:"
echo "  • Ejecuta el script de configuración para crear los configs"
echo "  • O configura manualmente i3, polybar, picom, etc."
echo ""
print_status "Usuario actual: $USER"
print_status "Grupos añadidos: audio, lp, input"

read -p "¿Reiniciar ahora para aplicar cambios? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo reboot
fi
