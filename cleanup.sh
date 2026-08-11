#!/bin/sh
# Script de desinstalación limpia y remoción completa del plugin GameControl

if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Error: Este script debe ejecutarse como root."
    exit 1
fi

echo "=== 1. Deteniendo y eliminando archivos del plugin ==="
rm -rf /usr/local/opnsense/mvc/app/models/OPNsense/GameControl
rm -rf /usr/local/opnsense/mvc/app/views/OPNsense/GameControl
rm -rf /usr/local/opnsense/mvc/app/controllers/OPNsense/GameControl
rm -rf /usr/local/opnsense/scripts/OPNsense/GameControl
rm -f /usr/local/opnsense/service/conf/actions.d/actions_gamecontrol.conf
rm -f /var/etc/gamecontrol_unblocked.json
rm -f /var/etc/gamecontrol_domains_cache.json
rm -f /var/log/gamecontrol.log

echo "=== 2. Limpiando cachés de OPNsense y PHP ==="
rm -f /tmp/opnsense_menu_cache.json
rm -rf /usr/local/opnsense/mvc/app/cache/*
rm -rf /tmp/volt_*

echo "=== 3. Reconstruyendo servicios y menú web de OPNsense ==="
/usr/local/etc/rc.configure_plugins
/usr/local/sbin/configctl template reload OPNsense/Menu >/dev/null 2>&1
/usr/local/sbin/pluginctl -s configd restart
/usr/local/sbin/pluginctl -c webgui restart

echo "=== ¡Desinstalación completa finalizada exitosamente! ==="
