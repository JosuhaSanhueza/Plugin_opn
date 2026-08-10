#!/bin/sh

echo "=== Desinstalando completamente GameControl y restaurando conectividad ==="

# 1. Eliminar todos los archivos, XML de menú, ACL y plantillas del plugin en todas las rutas del sistema
rm -rf /usr/local/opnsense/mvc/app/models/OPNsense/GameControl
rm -rf /usr/local/opnsense/mvc/app/views/OPNsense/GameControl
rm -rf /usr/local/opnsense/mvc/app/controllers/OPNsense/GameControl
rm -rf /usr/local/opnsense/scripts/OPNsense/GameControl
rm -rf /usr/local/opnsense/service/templates/OPNsense/GameControl
rm -f /usr/local/opnsense/service/conf/actions.d/actions_gamecontrol.conf
rm -f /usr/local/etc/unbound/gamecontrol.conf
rm -f /var/unbound/etc/gamecontrol.conf
rm -f /var/unbound/etc/gamecontrol.rpz
rm -f /usr/local/etc/unbound/unbound.conf.d/gamecontrol.conf
rm -f /var/etc/gamecontrol_unblocked.json
rm -f /var/etc/gamecontrol_pf_blocked.txt
find /usr/local/opnsense/ -iname "*GameControl*" -exec rm -rf {} +
find /tmp/ -name "*menu*" -exec rm -rf {} +
find /tmp/ -name "*acl*" -exec rm -rf {} +
find /tmp/ -name "*phalcon*" -exec rm -rf {} +
rm -f /var/etc/opnsense_menu_cache*
rm -f /var/run/opnsense_menu_cache*


# Limpiar entrada en /conf/config.xml si quedó alguna configuración guardada
if [ -f /conf/config.xml ]; then
    sed -i '' '/<GameControl>/,/<\/GameControl>/d' /conf/config.xml
fi

# Desregistrar paquete pkg de OPNsense si fue instalado como paquete
pkg delete -y os-gamecontrol >/dev/null 2>&1 || true



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

# 5. Forzar reconstrucción de caché de menú y ACL de OPNsense
/usr/local/sbin/configctl service reload all >/dev/null 2>&1
/usr/local/sbin/configctl webgui restart >/dev/null 2>&1
/usr/local/sbin/pluginctl -s configd restart
/usr/local/sbin/pluginctl -c webgui restart


echo "=== Desinstalación completada exitosamente. Conexión a internet y menú de OPNsense restaurados. ==="


