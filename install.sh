#!/bin/sh

# Script de instalación y registro en OPNsense 26.7

if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Error: Este script debe ejecutarse como root."
    exit 1
fi

echo "=== 1. Limpiando residuos anteriores ==="
rm -rf /usr/local/opnsense/mvc/app/models/OPNsense/GameControl
rm -rf /usr/local/opnsense/mvc/app/views/OPNsense/GameControl
rm -rf /usr/local/opnsense/mvc/app/controllers/OPNsense/GameControl
rm -rf /usr/local/opnsense/scripts/OPNsense/GameControl
rm -f /usr/local/opnsense/service/conf/actions.d/actions_gamecontrol.conf
rm -f /usr/local/etc/unbound/gamecontrol.conf
rm -f /tmp/opnsense_menu_cache.json

echo "=== 2. Copiando archivos del plugin ==="
cp -r usr/local/* /usr/local/

echo "=== 3. Asignando permisos de ejecución ==="
chmod +x /usr/local/opnsense/scripts/OPNsense/GameControl/update_rules.py

echo "=== 4. Ejecutando primera sincronización de reglas DNS y generando log ==="
/usr/local/opnsense/scripts/OPNsense/GameControl/update_rules.py

echo "=== 5. Reconstruyendo caché de menú, permisos ACL y servicios de OPNsense ==="
rm -f /tmp/opnsense_menu_cache.json
/usr/local/etc/rc.configure_plugins
/usr/local/sbin/configctl template reload OPNsense/Menu >/dev/null 2>&1
/usr/local/sbin/pluginctl -s configd restart
/usr/local/sbin/pluginctl -c webgui restart

echo "=== ¡Instalación limpia finalizada exitosamente! ==="






rm -rf /usr/local/opnsense/mvc/app/cache/*
rm -rf /tmp/volt_*
