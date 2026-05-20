#!/bin/bash
# =============================================================================
# CarlosOS Live Build - Script Unificado de Compilación
# =============================================================================
# Este script automatiza todo el proceso de construcción de la ISO de CarlosOS
# Basado en Debian Live-Build (bookworm)
# =============================================================================

set -e
set -o pipefail

# Pasar --no-check-gpg a debootstrap para evitar error de keyring
export DEBOOTSTRAP_OPTIONS="--no-check-gpg"

# =============================================================================
# CONFIGURACIÓN
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Variables de configuración
ISO_NAME="carlosos-live-1.0-amd64.hybrid.iso"
BUILD_LOG="build.log"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =============================================================================
# FUNCIONES
# =============================================================================

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1" | tee -a "$BUILD_LOG"
}

success() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] ✓${NC} $1" | tee -a "$BUILD_LOG"
}

warning() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠${NC} $1" | tee -a "$BUILD_LOG"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ✗${NC} ERROR: $1" | tee -a "$BUILD_LOG"
}

info() {
    echo -e "${CYAN}[$(date +'%H:%M:%S')] ℹ${NC} $1" | tee -a "$BUILD_LOG"
}

check_error() {
    if [ $? -ne 0 ]; then
        error "$1"
        exit 1
    fi
}

print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} $1"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_banner() {
    echo ""
    echo -e "${GREEN}"
    echo "   ____           _   ____   _____ "
    echo "  / ___|__ _ _ __| |_|  _ \ / ___|"
    echo " | |   / _\` | '__| __| | | | |  _ "
    echo " | |__| (_| | |  | |_| |_| | | | |"
    echo "  \____\__,_|_|   \__|____/|_| |_|"
    echo ""
    echo "        CarlosOS Live Build System v1.0"
    echo "   Sistema Operativo Personalizado - Debian Bookworm"
    echo "        © 2026 Carlos Torres - Todos los derechos reservados"
    echo -e "${NC}"
    echo ""
}

# =============================================================================
# VERIFICACIÓN DEL SISTEMA
# =============================================================================

verify_system() {
    print_header "VERIFICANDO SISTEMA"
    
    log "Verificando dependencias del sistema..."
    
    # Verificar si somos root
    if [ "$EUID" -ne 0 ]; then
        error "Este script debe ejecutarse como root (usa sudo)"
        exit 1
    fi
    
    # Verificar live-build
    if ! command -v lb &> /dev/null; then
        error "live-build no está instalado"
        info "Instala con: apt install live-build debootstrap"
        exit 1
    fi
    success "live-build instalado: $(lb --version 2>&1 | head -1)"
    
    # Verificar tar
    if ! tar --version >/dev/null 2>&1; then
        error "tar no funciona correctamente"
        exit 1
    fi
    success "tar funcional"
    
    # Verificar apt-get
    if ! apt-get --version >/dev/null 2>&1; then
        error "apt-get no funciona correctamente"
        exit 1
    fi
    success "apt-get funcional"
    
    # Verificar debootstrap
    if ! debootstrap --version >/dev/null 2>&1; then
        error "debootstrap no está instalado"
        exit 1
    fi
    success "debootstrap instalado"
    
    # Verificar librerías críticas
    if ! ldconfig -p | grep -q libstdc++; then
        error "libstdc++ no encontrada"
        exit 1
    fi
    success "libstdc++ disponible"
    
    # Verificar espacio en disco (mínimo 10GB)
    AVAILABLE_SPACE=$(df -P . | awk 'NR==2 {print $4}')
    MIN_SPACE=10485760  # 10GB en KB
    if [ "$AVAILABLE_SPACE" -lt "$MIN_SPACE" ]; then
        warning "Espacio en disco bajo: $((AVAILABLE_SPACE / 1024)) MB (mínimo recomendado: 10GB)"
    else
        success "Espacio en disco adecuado: $((AVAILABLE_SPACE / 1024)) MB"
    fi
    
    log "Verificación del sistema completada"
}

# =============================================================================
# PREPARACIÓN DEL ENTORNO
# =============================================================================

prepare_environment() {
    print_header "PREPARANDO ENTORNO"
    
    log "Instalando imágenes de CarlosOS..."
    if [ -f "$SCRIPT_DIR/install_images.sh" ]; then
        bash "$SCRIPT_DIR/install_images.sh"
        success "Imágenes instaladas"
    else
        warning "install_images.sh no encontrado, continuando sin imágenes personalizadas"
    fi
    
    log "Copiando aplicación VPN..."
    APP_SOURCE="$SCRIPT_DIR/27723"
    APP_DEST="$SCRIPT_DIR/config/includes.chroot/home/user/mi_app"
    
    if [ -d "$APP_SOURCE" ] && [ -f "$APP_SOURCE/package.json" ]; then
        mkdir -p "$APP_DEST"
        cp -r "$APP_SOURCE/." "$APP_DEST/"
        chown -R 1000:1000 "$APP_DEST" 2>/dev/null || true
        success "Aplicación VPN copiada a $APP_DEST"
    else
        warning "Aplicación VPN no encontrada en $APP_SOURCE"
    fi
    
    log "Limpiando builds anteriores..."
    lb clean --purge 2>/dev/null || true
    rm -rf chroot cache binary live .build 2>/dev/null || true
    success "Limpieza completada"
}

# =============================================================================
# CONFIGURACIÓN LIVE-BUILD
# =============================================================================

configure_live_build() {
    print_header "CONFIGURANDO LIVE-BUILD"
    
    log "Ejecutando auto/config..."
    
    if [ ! -f "auto/config" ]; then
        error "auto/config no encontrado"
        exit 1
    fi
    
    # Hacer ejecutable y ejecutar auto/config
    chmod +x auto/config
    bash auto/config
    
    check_error "Fallo en lb config"
    success "Live-build configurado"
}

# =============================================================================
# CONSTRUCCIÓN
# =============================================================================

build_iso() {
    print_header "CONSTRUYENDO ISO"
    
    log "Iniciando construcción de CarlosOS Live ISO..."
    log "Hora de inicio: $TIMESTAMP"
    
    # Limpiar caché de bootstrap para evitar corrupción
    rm -rf cache/bootstrap cache/cachefile packages* 2>/dev/null || true
    
    # Ejecutar lb build capturando exit code correctamente
    lb build 2>&1 | tee -a "$BUILD_LOG"
    local LB_EXIT=${PIPESTATUS[0]}
    
    if [ $LB_EXIT -eq 0 ]; then
        success "Construcción completada"
    else
        error "Fallo en la construcción"
        log "--- CONTENIDO DEL LOG DE ERRORES ---"
        tail -n 100 "$BUILD_LOG" || true
        exit 1
    fi
}

# =============================================================================
# VERIFICACIÓN
# =============================================================================

verify_iso() {
    print_header "VERIFICANDO ISO"
    
    # Buscar la ISO generada
    ISO_FILE=""
    for iso in live-image-*.iso carlosos-*.iso; do
        if [ -f "$iso" ]; then
            ISO_FILE="$iso"
            break
        fi
    done
    
    if [ -z "$ISO_FILE" ]; then
        error "No se encontró la ISO generada"
        exit 1
    fi
    
    success "ISO encontrada: $ISO_FILE"
    
    # Verificar tamaño
    ISO_SIZE=$(stat -c%s "$ISO_FILE" 2>/dev/null || stat -f%z "$ISO_FILE" 2>/dev/null || echo "0")
    ISO_SIZE_MB=$((ISO_SIZE / 1024 / 1024))
    
    if [ "$ISO_SIZE_MB" -lt 500 ]; then
        error "ISO demasiado pequeña: ${ISO_SIZE_MB}MB (mínimo esperado: 500MB)"
        exit 1
    fi
    success "Tamaño de ISO: ${ISO_SIZE_MB}MB"
    
    # Verificar con isoinfo si está disponible
    if command -v isoinfo &> /dev/null; then
        log "Verificando integridad con isoinfo..."
        if isoinfo -d -i "$ISO_FILE" >/dev/null 2>&1; then
            success "ISO válida según isoinfo"
        else
            warning "ISO podría tener problemas de integridad"
        fi
    fi
    
    # Montar y verificar archivos críticos
    MOUNT_POINT="/tmp/carlosos_iso_$$"
    mkdir -p "$MOUNT_POINT"
    
    if mount -o loop "$ISO_FILE" "$MOUNT_POINT" 2>/dev/null; then
        log "Verificando archivos críticos..."
        
        for file in "live/filesystem.squashfs" "live/initrd.img" "live/vmlinuz"; do
            if [ -f "$MOUNT_POINT/$file" ]; then
                success "$file encontrado"
            else
                warning "$file no encontrado"
            fi
        done
        
        # Verificar grub
        if [ -f "$MOUNT_POINT/boot/grub/grub.cfg" ]; then
            if grep -qi "carlosos" "$MOUNT_POINT/boot/grub/grub.cfg"; then
                success "GRUB configurado con branding CarlosOS"
            fi
        fi
        
        umount "$MOUNT_POINT" 2>/dev/null || true
        rmdir "$MOUNT_POINT" 2>/dev/null || true
    else
        warning "No se pudo montar la ISO para verificación"
    fi
    
    # Renombrar ISO
    if [ "$ISO_FILE" != "$ISO_NAME" ]; then
        mv "$ISO_FILE" "$ISO_NAME" 2>/dev/null || true
        success "ISO renombrada a: $ISO_NAME"
    fi
}

# =============================================================================
# RESUMEN
# =============================================================================

print_summary() {
    print_header "CONSTRUCCIÓN COMPLETADA"
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}     ${CYAN}CARLOSOS LIVE ISO GENERADA EXITOSAMENTE${NC}           ${GREEN}║${NC}"
    echo -e "${GREEN}╠════════════════════════════════════════════════════════╣${NC}"
    printf "${GREEN}║${NC}  %-50s ${GREEN}║\n" "Archivo: $ISO_NAME"
    printf "${GREEN}║${NC}  %-50s ${GREEN}║\n" "Tamaño: ${ISO_SIZE_MB}MB"
    printf "${GREEN}║${NC}  %-50s ${GREEN}║\n" "Ubicación: $SCRIPT_DIR"
    printf "${GREEN}║${NC}  %-50s ${GREEN}║\n" "Log: $BUILD_LOG"
    printf "${GREEN}║${NC}  %-50s ${GREEN}║\n" "© 2026 Carlos Torres"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    info "Para probar la ISO:"
    echo "   VirtualBox: VBoxManage createvm --name CarlosOS --register"
    echo "   QEMU: qemu-system-x86_64 -cdrom $ISO_NAME -m 4096"
    echo ""
    info "Para grabar en USB:"
    echo "   sudo dd if=$ISO_NAME of=/dev/sdX bs=4M status=progress"
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    print_banner
    
    log "Iniciando CarlosOS Live Build"
    log "Directorio: $SCRIPT_DIR"
    log "Fecha: $TIMESTAMP"
    echo ""
    
    # Ejecutar fases
    verify_system
    prepare_environment
    configure_live_build
    build_iso
    verify_iso
    print_summary
    
    success "¡CarlosOS Live está listo!"
}

# Manejo de argumentos
case "${1:-}" in
    --clean)
        log "Limpiando entorno de build..."
        lb clean --purge
        rm -rf chroot cache binary live 2>/dev/null || true
        success "Limpieza completada"
        exit 0
        ;;
    --help)
        echo "Uso: $0 [opción]"
        echo ""
        echo "Opciones:"
        echo "  --clean    Limpiar archivos de build anteriores"
        echo "  --help     Mostrar esta ayuda"
        echo ""
        echo "Sin argumentos: Inicia el build completo"
        exit 0
        ;;
    *)
        main
        ;;
esac
