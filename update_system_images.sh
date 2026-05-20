#!/bin/bash
# =============================================================================
# CarlosOS - Actualización de Imágenes de Sistema
# =============================================================================
# Este script reemplaza las imágenes PNG estáticas con componentes funcionales
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║     CARLOSOS - ACTUALIZACIÓN DE IMÁGENES DE SISTEMA   ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Las imágenes PNG estáticas ya no son necesarias porque ahora usamos:
# 1. Tema CSS para GDM (login funcional)
# 2. Extensión de GNOME para diálogo de poder (botones funcionales)
# 3. SVG para el logo (escalable y animado)

echo "Las siguientes imágenes PNG ahora son OPCIONALES:"
echo ""
echo "  - fondo para CarlosOS.png       → Fondo de escritorio"
echo "  - splash screen.png             → Splash de boot (Plymouth)"
echo "  - pantalla de inicio de sesión  → Reemplazado por tema CSS GDM"
echo "  - pantalla de apagadoreinicio   → Reemplazado por extensión GNOME"
echo ""

# Mover imágenes antiguas a backup (opcional)
BACKUP_DIR="$SCRIPT_DIR/images-backup"

echo "¿Deseas hacer backup de las imágenes PNG antiguas? (s/n)"
read -r response

if [[ "$response" =~ ^[sS]$ ]]; then
    mkdir -p "$BACKUP_DIR"
    
    for img in "*.png"; do
        if [ -f "$img" ]; then
            mv "$img" "$BACKUP_DIR/"
            echo "  ✓ Movido: $img → $BACKUP_DIR/"
        fi
    done
    
    echo ""
    echo "Backup completado en: $BACKUP_DIR"
fi

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║              COMPONENTES FUNCIONALES CREADOS           ║"
echo "╠════════════════════════════════════════════════════════╣"
echo "║  ✓ Tema GDM CSS         → Login con campo contraseña  ║"
echo "║  ✓ Extensión Power Dialog → Botones apagado/reinicio  ║"
echo "║  ✓ Logo SVG             → Logo escalable con efectos  ║"
echo "║  ✓ Atajo Super+P        → Abrir diálogo de poder     ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

echo "Para usar las imágenes PNG como fondos de escritorio:"
echo "  1. Mantén 'fondo para CarlosOS.png' en el root del proyecto"
echo "  2. El script install_images.sh la copiará automáticamente"
echo ""

echo "Para Plymouth (splash de boot):"
echo "  1. Mantén 'splash screen.png' en el root del proyecto"
echo "  2. Crea un tema de Plymouth en:"
echo "     /usr/share/plymouth/themes/carlosos/"
echo ""

echo "¡Listo! Los botones de apagado/reinicio ahora son funcionales."
echo ""
