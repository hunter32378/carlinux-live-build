#!/bin/bash
# =============================================================================
# CarlosOS - Script de Verificación Pre-Build
# =============================================================================
# Este script verifica que todo esté configurado correctamente antes de
# iniciar la compilación de la ISO.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((CHECKS_PASSED++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((CHECKS_FAILED++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((CHECKS_WARNING++))
}

check_header() {
    echo ""
    echo -e "${BLUE}=== $1 ===${NC}"
}

# =============================================================================
# VERIFICACIONES
# =============================================================================

echo ""
echo "   ____           _   ____   _____ "
echo "  / ___|__ _ _ __| |_|  _ \ / ___|"
echo " | |   / _\` | '__| __| | | | |  _ "
echo " | |__| (_| | |  | |_| |_| | | | |"
echo "  \____\__,_|_|   \__|____/|_| |_|"
echo ""
echo "        Verificación de Configuración"
echo ""

# 1. Verificar archivos de configuración
check_header "Archivos de Configuración"

if [ -f "auto/config" ]; then
    check_pass "auto/config existe"
else
    check_fail "auto/config no encontrado"
fi

if [ -f "config/package-lists/custom.list.chroot" ]; then
    check_pass "Lista de paquetes existe"
else
    check_fail "Lista de paquetes no encontrada"
fi

if [ -f "config/archives/sources.list.chroot" ]; then
    check_pass "sources.list.chroot existe"
else
    check_fail "sources.list.chroot no encontrado"
fi

# 2. Verificar hooks
check_header "Hooks de Personalización"

for hook in config/hooks/normal/*.hook.chroot; do
    if [ -f "$hook" ]; then
        if [ -x "$hook" ] || head -1 "$hook" | grep -q "^#!/"; then
            check_pass "$(basename $hook) está configurado"
        else
            check_warn "$(basename $hook) no es ejecutable"
        fi
    fi
done

# 3. Verificar imágenes
check_header "Imágenes Personalizadas"

IMAGES_DIR="$SCRIPT_DIR"
for img in "fondo para CarlosOS.png" "splash screen.png" "pantalla de inicio de sesión de CarlosOS.png" "pantalla de apagadoreinicio de CarlosOS.png"; do
    if [ -f "$IMAGES_DIR/$img" ]; then
        SIZE=$(stat -c%s "$IMAGES_DIR/$img" 2>/dev/null || stat -f%z "$IMAGES_DIR/$img" 2>/dev/null || echo "0")
        SIZE_MB=$((SIZE / 1024 / 1024))
        if [ "$SIZE_MB" -gt 0 ]; then
            check_pass "$img (${SIZE_MB}MB)"
        else
            check_warn "$img existe pero parece vacío"
        fi
    else
        check_warn "$img no encontrado (opcional)"
    fi
done

# 4. Verificar aplicación VPN
check_header "Aplicación VPN"

if [ -d "27723" ]; then
    check_pass "Directorio 27723 existe"
    
    if [ -f "27723/package.json" ]; then
        check_pass "package.json encontrado"
        
        # Verificar si es un proyecto Expo válido
        if grep -q "expo" "27723/package.json"; then
            check_pass "Proyecto Expo detectado"
        else
            check_warn "package.json no parece ser de Expo"
        fi
    else
        check_warn "package.json no encontrado"
    fi
    
    if [ -f "27723/App.js" ]; then
        check_pass "App.js encontrado"
    else
        check_warn "App.js no encontrado"
    fi
else
    check_warn "Directorio de la aplicación no encontrado"
fi

# 5. Verificar configuración GRUB
check_header "Configuración de Boot"

if [ -f "config/includes.binary/boot/grub/grub.cfg" ]; then
    if grep -qi "carlosos" "config/includes.binary/boot/grub/grub.cfg"; then
        check_pass "GRUB configurado con branding CarlosOS"
    else
        check_warn "GRUB existe pero sin branding CarlosOS"
    fi
else
    check_warn "grub.cfg no encontrado (se usará el por defecto)"
fi

if [ -f "config/includes.binary/isolinux/isolinux.cfg" ]; then
    check_pass "isolinux.cfg configurado"
else
    check_warn "isolinux.cfg no encontrado (boot legacy puede fallar)"
fi

# 6. Verificar scripts
check_header "Scripts de Build"

for script in "build_carlosos.sh" "build_iso.sh" "install_images.sh"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ] || head -1 "$script" | grep -q "^#!/"; then
            check_pass "$script está disponible"
        else
            check_warn "$script no es ejecutable"
        fi
    else
        check_warn "$script no encontrado"
    fi
done

# 7. Verificar sistema (solo en Linux)
check_header "Verificación del Sistema"

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Estamos en Linux
    if command -v lb &> /dev/null; then
        check_pass "live-build instalado: $(lb --version 2>&1 | head -1)"
    else
        check_fail "live-build no está instalado"
    fi
    
    if command -v debootstrap &> /dev/null; then
        check_pass "debootstrap instalado"
    else
        check_fail "debootstrap no está instalado"
    fi
    
    if tar --version >/dev/null 2>&1; then
        check_pass "tar funcional"
    else
        check_fail "tar no funciona"
    fi
    
    # Verificar espacio en disco
    AVAILABLE_SPACE=$(df -P . | awk 'NR==2 {print $4}')
    MIN_SPACE=10485760  # 10GB en KB
    if [ "$AVAILABLE_SPACE" -ge "$MIN_SPACE" ]; then
        check_pass "Espacio en disco: $((AVAILABLE_SPACE / 1024))MB"
    else
        check_fail "Espacio insuficiente: $((AVAILABLE_SPACE / 1024))MB (mínimo: 10GB)"
    fi
    
    # Verificar si somos root
    if [ "$EUID" -eq 0 ]; then
        check_pass "Ejecutando como root"
    else
        check_warn "No se está ejecutando como root (se requerirá sudo para build)"
    fi
else
    check_warn "No es un sistema Linux - algunas verificaciones se omiten"
    check_warn "El build debe ejecutarse en Linux o WSL2"
fi

# =============================================================================
# RESUMEN
# =============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║                    RESUMEN                            ║"
echo "╠════════════════════════════════════════════════════════╣"
printf "║  %-20s %s\n" "Verificados:" "${CHECKS_PASSED}"
printf "║  %-20s %s\n" "Advertencias:" "${CHECKS_WARNING}"
printf "║  %-20s %s\n" "Fallidos:" "${CHECKS_FAILED}"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

if [ "$CHECKS_FAILED" -gt 0 ]; then
    echo -e "${RED}⚠ Hay $CHECKS_FAILED verificaciones fallidas${NC}"
    echo "Por favor corrige los errores antes de continuar con el build."
    echo ""
    exit 1
elif [ "$CHECKS_WARNING" -gt 0 ]; then
    echo -e "${YELLOW}⚠ Hay $CHECKS_WARNING advertencias${NC}"
    echo "Puedes continuar con el build, pero algunas funciones pueden no estar disponibles."
    echo ""
else
    echo -e "${GREEN}✓ Todas las verificaciones pasaron${NC}"
    echo "El sistema está listo para compilar."
    echo ""
    echo "Para iniciar el build, ejecuta:"
    echo "  sudo bash build_carlosos.sh"
    echo ""
fi
