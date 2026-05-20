# CarlosOS Live Build

Sistema operativo Linux personalizado basado en **Debian GNU/Linux Bookworm**.

![CarlosOS Logo](fondo%20para%20CarlosOS.png)

## 📋 Características

- **Base**: Debian 12 (Bookworm)
- **Arquitectura**: AMD64 (x86_64)
- **Escritorio**: GNOME
- **Idioma**: Español (multilenguaje disponible)
- **Aplicación incluida**: CarlosOS VPN (React Native/Expo)

## 🛠️ Requisitos del Sistema

### Para compilar la ISO:
- Sistema Linux (Debian/Ubuntu recomendado) o WSL2
- Mínimo 15GB de espacio libre en disco
- 4GB de RAM mínimo (8GB recomendado)
- Conexión a internet
- Root/sudo privileges

### Para ejecutar CarlosOS:
- CPU: 2 núcleos (4 núcleos recomendado)
- RAM: 4GB mínimo (8GB recomendado)
- Almacenamiento: 25GB mínimo
- GPU: Soporte para aceleración 3D

## 📦 Instalación de Dependencias

### En Debian/Ubuntu:

```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependencias esenciales
sudo apt install -y live-build debootstrap build-essential \
    tar dpkg-dev git curl wget

# Verificar instalación
lb --version
```

### En WSL2 (Windows Subsystem for Linux):

```bash
# Actualizar
sudo apt update

# Instalar dependencias
sudo apt install -y live-build debootstrap build-essential \
    tar dpkg-dev dosfstools grub-pc-bin grub-efi-amd64-bin \
    isolinux syslinux-efi

# Nota: La creación de ISO en WSL2 puede tener limitaciones
```

## 🚀 Construcción de la ISO

### Método 1: Script Unificado (Recomendado)

```bash
# Navegar al directorio del proyecto
cd /path/to/carlinux-live-build

# Ejecutar script de construcción
sudo bash build_carlosos.sh
```

### Método 2: Scripts Individuales

```bash
# 1. Instalar imágenes personalizadas
bash install_images.sh

# 2. Configurar y construir
sudo bash build_iso.sh
```

### Método 3: Comandos Manuales

```bash
# Limpiar builds anteriores
sudo lb clean --purge

# Configurar
sudo lb config

# Construir
sudo lb build
```

## 📁 Estructura del Proyecto

```
carlinux-live-build/
├── auto/
│   └── config              # Configuración de live-build
├── config/
│   ├── archives/           # Repositorios APT
│   ├── binary/             # Archivos para la ISO
│   ├── hooks/              # Scripts de personalización
│   │   ├── normal/         # Hooks en fase normal
│   │   └── archives/       # Hooks de repositorios
│   ├── includes.chroot/    # Archivos en el sistema chroot
│   ├── includes.binary/    # Archivos en la ISO final
│   └── package-lists/      # Lista de paquetes a instalar
├── 27723/                  # Aplicación VPN (React Native)
├── build_carlosos.sh       # Script principal de build
├── build_iso.sh            # Script alternativo de build
├── install_images.sh       # Script para instalar imágenes
└── README.md               # Este archivo
```

## 🎨 Personalización

### 🖼️ Imágenes de Fondo

Las siguientes imágenes se incluyen automáticamente:

| Imagen | Función | Estado |
|--------|---------|--------|
| `fondo para CarlosOS.png` | Fondo de escritorio | ✅ Funcional |
| `splash screen.png` | Splash de boot (Plymouth) | ✅ Funcional |
| Login GDM | Pantalla de inicio de sesión | ✅ **Tema CSS funcional** |
| Power Dialog | Apagado/Reinicio | ✅ **Extensión con botones reales** |

### ⚡ Componentes Funcionales Élite

#### 1. **Pantalla de Login (GDM Theme)**
- Campo de contraseña **funcional**
- Logo animado con efecto neón
- Fondo gradiente animado
- Botón "Sign In" interactivo
- Atajos de teclado configurados

**Ubicación:** `/usr/share/gnome-shell/theme/carlosos-gdm.css`

#### 2. **Diálogo de Apagado/Reinicio (Power Dialog)**
- **Botones 100% funcionales:**
  - 🔌 Apagar
  - 🔄 Reiniciar
  - ⏸️ Suspender
  - 🚪 Cerrar Sesión
- Confirmación antes de ejecutar acciones
- Animaciones suaves
- Estilo élite con efectos glow

**Ubicación:** `/usr/share/gnome-shell/extensions/carlosos-power-dialog@carlosos.org/`

#### 3. **Atajos de Teclado**
| Atajo | Acción |
|-------|--------|
| `Super + P` | Abrir diálogo de poder |
| `Esc` | Cancelar/Cerrar diálogo |
| `Enter` | Confirmar acción |

### 📦 Paquetes

Edita `config/package-lists/custom.list.chroot` para agregar o quitar paquetes.

### Configuración del Sistema

Los hooks en `config/hooks/normal/` personalizan:
- Hostname y branding
- Mensajes de bienvenida
- Configuración de GNOME
- Aplicación VPN

## 🔧 Aplicación CarlosOS VPN

La ISO incluye una aplicación VPN desarrollada con React Native/Expo.

### Ubicación en la ISO:
```
/home/user/mi_app/
```

### Ejecutar la aplicación:
```bash
# Desde terminal
cd /home/user/mi_app
npm start

# O usar el lanzador
carlosos-vpn
```

### Dependencias:
- Node.js
- npm
- Expo CLI

## 📝 Configuración de GRUB

El menú de boot incluye:
- Boot normal
- Modo seguro (failsafe)
- Modo persistente
- Modo forense
- Modo debug
- Test de memoria
- Apagar/Reiniciar

## 🧪 Pruebas de la ISO

### Con QEMU:
```bash
qemu-system-x86_64 -cdrom carlosos-live-1.0-amd64.hybrid.iso \
    -m 4096 -boot d -enable-kvm
```

### Con VirtualBox:
```bash
# Crear VM
VBoxManage createvm --name "CarlosOS" --register

# Configurar RAM y almacenamiento
VBoxManage modifyvm "CarlosOS" --memory 4096
VBoxManage createhd --filename CarlosOS.vdi --size 25600

# Configurar controlador SATA y adjuntar ISO
VBoxManage storagectl "CarlosOS" --name "SATA" --add sata
VBoxManage storageattach "CarlosOS" --storagectl "SATA" \
    --port 0 --type dvddrive --medium carlosos-live-1.0-amd64.hybrid.iso

# Iniciar VM
VBoxManage startvm "CarlosOS" --type gui
```

## 💾 Grabar en USB

### Método 1: dd (Linux/macOS)
```bash
sudo dd if=carlosos-live-1.0-amd64.hybrid.iso \
    of=/dev/sdX bs=4M status=progress && sync
```

### Método 2: Rufus (Windows)
1. Descargar Rufus desde https://rufus.ie
2. Seleccionar la ISO de CarlosOS
3. Seleccionar dispositivo USB
4. Click en "Empezar"

### Método 3: balenaEtcher (Multiplataforma)
1. Descargar desde https://www.balena.io/etcher/
2. Seleccionar ISO
3. Seleccionar USB
4. Click en "Flash!"

## 🐛 Solución de Problemas

### Error: libstdc++.so.6 no encontrada
```bash
sudo apt install libstdc++6 libgcc-s1
```

### Error: live-build no está instalado
```bash
sudo apt install live-build debootstrap
```

### Error: Espacio insuficiente
```bash
# Limpiar caché
sudo lb clean --purge
sudo apt clean
```

### Build falla en debootstrap
```bash
# Verificar mirrors
cat config/archives/sources.list.chroot

# Ejecutar fix de entorno
sudo bash fix_build_environment.sh
```

## 📊 Paquetes Incluidos

### Sistema Base
- GNOME Desktop Environment
- Linux Kernel (último stable)
- Firmware no-free para hardware

### Aplicaciones
- **Navegadores**: Firefox ESR, Chromium
- **Oficina**: LibreOffice completo
- **Multimedia**: VLC, MPV, Rhythmbox
- **Gráficos**: GIMP, Inkscape
- **Desarrollo**: GCC, Python, Node.js, Git
- **Utilidades**: GParted, Timeshift, BleachBit

### Herramientas de Sistema
- Network Manager
- PulseAudio
- Bluetooth
- Impresión (CUPS)

## 🔐 Seguridad

- AppArmor habilitado
- Firewall (UFW) disponible
- Actualizaciones de seguridad automáticas
- ClamAV para antivirus

## 📞 Soporte

- **Sitio web**: https://carlosos.org
- **Email**: soporte@carlosos.org
- **Documentación**: /usr/share/doc/carlosos

## 📄 Licencia

CarlosOS está basado en Debian GNU/Linux y se distribuye bajo los términos de la licencia GPL.

## 🙏 Créditos

- **Debian Project** - https://www.debian.org
- **Live-Build** - https://salsa.debian.org/live-team/live-build
- **GNOME Project** - https://www.gnome.org

---

**CarlosOS Live 1.0** - Hecho con ❤️ para la comunidad
