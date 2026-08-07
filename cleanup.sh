#!/bin/sh

# Script de limpieza total para instalaciones manuales anteriores de GameControl

echo "=== Limpiando archivos previos de GameControl ==="

rm -rf /usr/local/opnsense/mvc/app/models/OPNsense/GameControl
rm -rf /usr/local/opnsense/mvc/app/views/OPNsense/GameControl
rm -rf /usr/local/opnsense/mvc/app/controllers/OPNsense/GameControl
rm -rf /usr/local/opnsense/scripts/OPNsense/GameControl
rm -f /usr/local/opnsense/service/conf/actions.d/actions_gamecontrol.conf
rm -f /usr/local/etc/unbound/gamecontrol.conf
rm -f /tmp/opnsense_menu_cache.json
rm -f /tmp/os-gamecontrol*

echo "=== Limpieza completada. Servicio configd y cache reseteados ==="
/usr/local/sbin/pluginctl -s configd restart
/usr/local/sbin/pluginctl -c webgui restart
