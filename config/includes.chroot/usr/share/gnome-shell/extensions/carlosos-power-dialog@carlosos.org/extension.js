/* =============================================================================
   CarlosOS Power Dialog Extension
   Extensión para diálogo de apagado/reinicio profesional
   ============================================================================= */

const { GObject, St, Clutter, GLib } = imports.gi;
const Main = imports.ui.main;
const ModalDialog = imports.ui.modalDialog;
const PanelMenu = imports.ui.panelMenu;
const PopupMenu = imports.ui.popupMenu;
const Gio = imports.gi.Gio;

// =============================================================================
// DIALOGO DE PODER PRINCIPAL
// =============================================================================

var CarlosOSPowerDialog = GObject.registerClass(
class CarlosOSPowerDialog extends ModalDialog.ModalDialog {
    _init() {
        super._init({
            styleClass: 'carlosos-power-dialog',
            destroyOnClose: true,
        });

        this._buildLayout();
    }

    _buildLayout() {
        const layout = new St.BoxLayout({
            style_class: 'carlosos-power-dialog-layout',
            vertical: true,
            x_align: Clutter.ActorAlign.CENTER,
            y_align: Clutter.ActorAlign.CENTER,
        });

        // Logo CarlosOS
        const logoBox = this._createLogo();
        layout.add_child(logoBox);

        // Título
        const title = this._createTitle();
        layout.add_child(title);

        // Subtítulo
        const subtitle = this._createSubtitle();
        layout.add_child(subtitle);

        // Botones de acción
        const buttonBox = this._createButtonBox();
        layout.add_child(buttonBox);

        // Información del sistema
        const systemInfo = this._createSystemInfo();
        layout.add_child(systemInfo);

        this.contentLayout.add_child(layout);
    }

    _createLogo() {
        const logoContainer = new St.BoxLayout({
            style_class: 'carlosos-logo-container',
            x_align: Clutter.ActorAlign.CENTER,
            y_align: Clutter.ActorAlign.CENTER,
            vertical: true,
        });

        // Icono/logo
        const logoIcon = new St.Icon({
            icon_name: 'system-run-symbolic',
            icon_size: 120,
            style_class: 'carlosos-logo-icon',
        });

        logoContainer.add_child(logoIcon);

        return logoContainer;
    }

    _createTitle() {
        const title = new St.Label({
            text: 'CarlosOS',
            style_class: 'carlosos-power-title',
            x_align: Clutter.ActorAlign.CENTER,
        });

        return title;
    }

    _createSubtitle() {
        const subtitle = new St.Label({
            text: '¿Qué deseas hacer?',
            style_class: 'carlosos-power-subtitle',
            x_align: Clutter.ActorAlign.CENTER,
        });

        return subtitle;
    }

    _createButtonBox() {
        const buttonBox = new St.BoxLayout({
            style_class: 'carlosos-button-box',
            x_align: Clutter.ActorAlign.CENTER,
            y_align: Clutter.ActorAlign.CENTER,
            vertical: true,
        });

        // Fila 1: Suspender y Cerrar Sesión
        const row1 = new St.BoxLayout({
            style_class: 'carlosos-button-row',
            x_align: Clutter.ActorAlign.CENTER,
        });

        const suspendButton = this._createActionButton(
            'media-playback-pause-symbolic',
            'Suspender',
            () => this._suspend()
        );
        row1.add_child(suspendButton);

        const logoutButton = this._createActionButton(
            'system-log-out-symbolic',
            'Cerrar Sesión',
            () => this._logout()
        );
        row1.add_child(logoutButton);

        buttonBox.add_child(row1);

        // Fila 2: Apagar y Reiniciar (botones principales)
        const row2 = new St.BoxLayout({
            style_class: 'carlosos-button-row',
            x_align: Clutter.ActorAlign.CENTER,
        });

        const shutdownButton = this._createActionButton(
            'system-shutdown-symbolic',
            'Apagar',
            () => this._shutdown(),
            'primary'
        );
        row2.add_child(shutdownButton);

        const rebootButton = this._createActionButton(
            'system-reboot-symbolic',
            'Reiniciar',
            () => this._reboot(),
            'primary'
        );
        row2.add_child(rebootButton);

        buttonBox.add_child(row2);

        // Botón Cancelar
        const cancelButton = this._createCancelButton();
        buttonBox.add_child(cancelButton);

        return buttonBox;
    }

    _createActionButton(iconName, label, callback, type = 'normal') {
        const button = new St.Button({
            style_class: `carlosos-action-button ${type === 'primary' ? 'carlosos-action-button-primary' : ''}`,
            can_focus: true,
            track_hover: true,
            x_expand: true,
            y_expand: false,
        });

        const buttonContent = new St.BoxLayout({
            style_class: 'carlosos-button-content',
            vertical: true,
            x_align: Clutter.ActorAlign.CENTER,
            y_align: Clutter.ActorAlign.CENTER,
        });

        const icon = new St.Icon({
            icon_name: iconName,
            icon_size: 48,
            style_class: 'carlosos-button-icon',
        });

        const labelActor = new St.Label({
            text: label,
            style_class: 'carlosos-button-label',
            x_align: Clutter.ActorAlign.CENTER,
        });

        buttonContent.add_child(icon);
        buttonContent.add_child(labelActor);
        button.set_child(buttonContent);

        button.connect('clicked', callback);
        button.connect('key-press-event', (actor, event) => {
            if (event.get_key_symbol() === Clutter.KEY_Return ||
                event.get_key_symbol() === Clutter.KEY_space) {
                callback();
                return Clutter.EVENT_STOP;
            }
            return Clutter.EVENT_PROPAGATE;
        });

        return button;
    }

    _createCancelButton() {
        const cancelButton = new St.Button({
            style_class: 'carlosos-cancel-button',
            can_focus: true,
            track_hover: true,
            x_align: Clutter.ActorAlign.CENTER,
            margin_top: 20,
        });

        const cancelLabel = new St.Label({
            text: 'Cancelar',
            style_class: 'carlosos-cancel-label',
        });

        cancelButton.set_child(cancelLabel);
        cancelButton.connect('clicked', () => this.close());
        cancelButton.connect('key-press-event', (actor, event) => {
            if (event.get_key_symbol() === Clutter.KEY_Escape) {
                this.close();
                return Clutter.EVENT_STOP;
            }
            return Clutter.EVENT_PROPAGATE;
        });

        return cancelButton;
    }

    _createSystemInfo() {
        const systemInfo = new St.BoxLayout({
            style_class: 'carlosos-system-info',
            x_align: Clutter.ActorAlign.CENTER,
            vertical: true,
        });

        // Obtener información del sistema
        const hostname = GLib.get_host_name() || 'CarlosOS';
        const uptime = this._getUptime();

        const infoLabel = new St.Label({
            text: `${hostname} • ${uptime}`,
            style_class: 'carlosos-info-label',
            x_align: Clutter.ActorAlign.CENTER,
        });

        systemInfo.add_child(infoLabel);

        return systemInfo;
    }

    _getUptime() {
        try {
            const uptimeFile = Gio.File.new_for_path('/proc/uptime');
            const [success, contents] = uptimeFile.load_contents(null);
            if (success) {
                const uptimeSeconds = parseFloat(new TextDecoder().decode(contents).split(' ')[0]);
                const hours = Math.floor(uptimeSeconds / 3600);
                const minutes = Math.floor((uptimeSeconds % 3600) / 60);
                return `Activo: ${hours}h ${minutes}m`;
            }
        } catch (e) {
            logError(e);
        }
        return 'Sistema listo';
    }

    // =============================================================================
    // ACCIONES DE PODER
    // =============================================================================

    _shutdown() {
        this._showConfirmationDialog(
            '¿Apagar el sistema?',
            'El sistema se apagará completamente.',
            () => {
                const shellProxy = new Gio.DBusProxy({
                    g_connection: Gio.DBus.system,
                    g_flags: Gio.DBusProxyFlags.DO_NOT_LOAD_PROPERTIES,
                    g_name: 'org.gnome.SessionManager',
                    g_object_path: '/org/gnome/SessionManager',
                    g_interface_name: 'org.gnome.SessionManager',
                });
                shellProxy.ShutdownRemote(0);
            }
        );
    }

    _reboot() {
        this._showConfirmationDialog(
            '¿Reiniciar el sistema?',
            'El sistema se reiniciará.',
            () => {
                const shellProxy = new Gio.DBusProxy({
                    g_connection: Gio.DBus.system,
                    g_flags: Gio.DBusProxyFlags.DO_NOT_LOAD_PROPERTIES,
                    g_name: 'org.gnome.SessionManager',
                    g_object_path: '/org/gnome/SessionManager',
                    g_interface_name: 'org.gnome.SessionManager',
                });
                shellProxy.RebootRemote();
            }
        );
    }

    _suspend() {
        this.close();
        Main.legacySessionProxy.SuspendRemote();
    }

    _logout() {
        this._showConfirmationDialog(
            '¿Cerrar sesión?',
            'Se cerrará la sesión actual.',
            () => {
                Main.sessionMode.logout();
            }
        );
    }

    _showConfirmationDialog(title, message, onConfirm) {
        const confirmDialog = new ModalDialog.ModalDialog({
            styleClass: 'carlosos-confirm-dialog',
        });

        const layout = new St.BoxLayout({
            vertical: true,
            style_class: 'carlosos-confirm-layout',
        });

        const titleLabel = new St.Label({
            text: title,
            style_class: 'carlosos-confirm-title',
            x_align: Clutter.ActorAlign.CENTER,
        });

        const messageLabel = new St.Label({
            text: message,
            style_class: 'carlosos-confirm-message',
            x_align: Clutter.ActorAlign.CENTER,
        });

        const buttonBox = new St.BoxLayout({
            style_class: 'carlosos-confirm-buttons',
            x_align: Clutter.ActorAlign.CENTER,
        });

        const confirmButton = new St.Button({
            style_class: 'carlosos-confirm-button',
            can_focus: true,
            track_hover: true,
            x_expand: true,
        });
        confirmButton.set_child(new St.Label({ text: 'Confirmar' }));
        confirmButton.connect('clicked', () => {
            confirmDialog.close();
            onConfirm();
        });

        const cancelButton = new St.Button({
            style_class: 'carlosos-cancel-button',
            can_focus: true,
            track_hover: true,
            x_expand: true,
            margin_start: 10,
        });
        cancelButton.set_child(new St.Label({ text: 'Cancelar' }));
        cancelButton.connect('clicked', () => confirmDialog.close());

        buttonBox.add_child(confirmButton);
        buttonBox.add_child(cancelButton);

        layout.add_child(titleLabel);
        layout.add_child(messageLabel);
        layout.add_child(buttonBox);

        confirmDialog.contentLayout.add_child(layout);
        confirmDialog.open();
    }
});

// =============================================================================
// INDICADOR DEL PANEL
// =============================================================================

var CarlosOSPowerIndicator = GObject.registerClass(
class CarlosOSPowerIndicator extends PanelMenu.Button {
    _init() {
        super._init(0.0, 'CarlosOS Power', false);

        const icon = new St.Icon({
            icon_name: 'system-shutdown-symbolic',
            style_class: 'system-status-icon',
        });

        this.add_child(icon);

        this._buildMenu();
    }

    _buildMenu() {
        const item1 = new PopupMenu.PopupMenuItem('Abrir diálogo de apagado...');
        item1.connect('activate', () => {
            this._openPowerDialog();
        });
        this.menu.addMenuItem(item1);

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        const shutdownItem = new PopupMenu.PopupMenuItem('Apagar');
        shutdownItem.connect('activate', () => {
            this._shutdown();
        });
        this.menu.addMenuItem(shutdownItem);

        const rebootItem = new PopupMenu.PopupMenuItem('Reiniciar');
        rebootItem.connect('activate', () => {
            this._reboot();
        });
        this.menu.addMenuItem(rebootItem);
    }

    _openPowerDialog() {
        const dialog = new CarlosOSPowerDialog();
        dialog.open();
        this.menu.close();
    }

    _shutdown() {
        const shellProxy = new Gio.DBusProxy({
            g_connection: Gio.DBus.system,
            g_flags: Gio.DBusProxyFlags.DO_NOT_LOAD_PROPERTIES,
            g_name: 'org.gnome.SessionManager',
            g_object_path: '/org/gnome/SessionManager',
            g_interface_name: 'org.gnome.SessionManager',
        });
        shellProxy.ShutdownRemote(0);
    }

    _reboot() {
        const shellProxy = new Gio.DBusProxy({
            g_connection: Gio.DBus.system,
            g_flags: Gio.DBusProxyFlags.DO_NOT_LOAD_PROPERTIES,
            g_name: 'org.gnome.SessionManager',
            g_object_path: '/org/gnome/SessionManager',
            g_interface_name: 'org.gnome.SessionManager',
        });
        shellProxy.RebootRemote();
    }
});

// =============================================================================
// INICIALIZACIÓN DE LA EXTENSIÓN
// =============================================================================

let powerIndicator = null;

function init() {
    log('CarlosOS Power Dialog initialized');
}

function enable() {
    log('CarlosOS Power Dialog enabled');
    powerIndicator = new CarlosOSPowerIndicator();
    Main.panel.addToStatusArea('carlosos-power', powerIndicator, 0, 'right');
}

function disable() {
    log('CarlosOS Power Dialog disabled');
    if (powerIndicator) {
        powerIndicator.destroy();
        powerIndicator = null;
    }
}

// =============================================================================
// ABRIR DIÁLOGO CON ATAJOS DE TECLADO
// =============================================================================

function openPowerDialog() {
    if (!powerIndicator) return;
    const dialog = new CarlosOSPowerDialog();
    dialog.open();
}
