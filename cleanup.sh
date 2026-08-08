#!/bin/sh

echo "=== Desinstalando completamente GameControl y restaurando conectividad ==="

# 1. Eliminar archivos del plugin
rm -rf /usr/local/opnsense/mvc/app/models/OPNsense/GameControl
rm -rf /usr/local/opnsense/mvc/app/views/OPNsense/GameControl
rm -rf /usr/local/opnsense/mvc/app/controllers/OPNsense/GameControl
rm -rf /usr/local/opnsense/scripts/OPNsense/GameControl
rm -f /usr/local/opnsense/service/conf/actions.d/actions_gamecontrol.conf
rm -f /usr/local/etc/unbound/gamecontrol.conf
rm -f /var/unbound/etc/gamecontrol.conf
rm -f /var/unbound/etc/gamecontrol.rpz
rm -f /usr/local/etc/unbound/unbound.conf.d/gamecontrol.conf
rm -f /var/etc/gamecontrol_unblocked.json
rm -f /var/etc/gamecontrol_pf_blocked.txt
rm -f /tmp/opnsense_menu_cache.json
rm -f /tmp/os-gamecontrol*

# 2. Limpiar inclusión en /var/unbound/unbound.conf
if [ -f /var/unbound/unbound.conf ]; then
    sed -i '' '/gamecontrol/d' /var/unbound/unbound.conf
fi

# 3. Remover la tabla de cortafuegos si existe
/sbin/pfctl -t game_blocked_ips -T kill >/dev/null 2>&1

# 4. Regenerar plantillas oficiales de Unbound y reiniciar el resolver
/usr/local/sbin/configctl template reload OPNsense/Unbound >/dev/null 2>&1
/usr/local/sbin/configctl unbound dnsbl >/dev/null 2>&1
/usr/local/sbin/unbound-control reload >/dev/null 2>&1 || /usr/local/sbin/pluginctl -s unbound restart

# 5. Reiniciar configd y WebGUI
/usr/local/sbin/pluginctl -s configd restart
/usr/local/sbin/pluginctl -c webgui restart

echo "=== Desinstalación completada exitosamente. Conexión a internet restaurada. ==="

