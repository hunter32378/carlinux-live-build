#!/bin/bash
# Script para instalar las imágenes de CarlosOS en la ISO

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== INSTALANDO IMÁGENES DE CARLOSOS ==="

# Directorios de origen (imágenes en el root del proyecto)
SRC_WALLPAPER="fondo para CarlosOS.png"
SRC_SPLASH="splash screen.png"
SRC_LOGIN="pantalla de inicio de sesión de CarlosOS.png"
SRC_SHUTDOWN="pantalla de apagadoreinicio de CarlosOS.png"

# Directorios de destino en la configuración de live-build
DEST_CHROOT_BG="config/includes.chroot/usr/share/backgrounds/carlosos"
DEST_CHROOT_IMG="config/includes.chroot/usr/share/images/desktop-background"
DEST_BOOT="config/includes.binary/isolinux"

# Crear directorios
mkdir -p "$DEST_CHROOT_BG"
mkdir -p "$DEST_CHROOT_IMG"
mkdir -p "$DEST_BOOT"

# Copiar fondo de pantalla principal
if [ -f "$SRC_WALLPAPER" ]; then
    cp "$SRC_WALLPAPER" "$DEST_CHROOT_BG/fondo-carlosos.png"
    cp "$SRC_WALLPAPER" "$DEST_CHROOT_BG/default.png"
    cp "$SRC_WALLPAPER" "$DEST_CHROOT_IMG/background.png"
    echo "✓ Fondo de pantalla copiado"
else
    echo "⚠ ADVERTENCIA: No se encontró $SRC_WALLPAPER"
fi

# Copiar splash screen para boot
if [ -f "$SRC_SPLASH" ]; then
    cp "$SRC_SPLASH" "$DEST_BOOT/splash.png"
    cp "$SRC_SPLASH" "$DEST_CHROOT_BG/splash.png"
    echo "✓ Splash screen copiado"
else
    echo "⚠ ADVERTENCIA: No se encontró $SRC_SPLASH"
fi

# Copiar pantalla de login (para GDM)
if [ -f "$SRC_LOGIN" ]; then
    cp "$SRC_LOGIN" "$DEST_CHROOT_BG/login-background.png"
    echo "✓ Pantalla de login copiada"
else
    echo "⚠ ADVERTENCIA: No se encontró $SRC_LOGIN"
fi

# Copiar pantalla de shutdown
if [ -f "$SRC_SHUTDOWN" ]; then
    cp "$SRC_SHUTDOWN" "$DEST_CHROOT_BG/shutdown-background.png"
    echo "✓ Pantalla de shutdown copiada"
else
    echo "⚠ ADVERTENCIA: No se encontró $SRC_SHUTDOWN"
fi

# Crear archivo XML para fondos de GNOME
cat > "$DEST_CHROOT_BG/carlosos-backgrounds.xml" << 'EOF'
<background>
  <starttime>
    <year>2024</year>
    <month>01</month>
    <day>01</day>
    <hour>0</hour>
    <minute>0</minute>
    <second>0</second>
  </starttime>
  <static>
    <duration>86400.0</duration>
    <file>/usr/share/backgrounds/carlosos/fondo-carlosos.png</file>
  </static>
</background>
EOF

echo ""
echo "=== IMÁGENES INSTALADAS CORRECTAMENTE ==="
echo "Ubicaciones:"
echo "  - Fondos: $DEST_CHROOT_BG"
echo "  - Imágenes: $DEST_CHROOT_IMG"
echo "  - Boot: $DEST_BOOT"
