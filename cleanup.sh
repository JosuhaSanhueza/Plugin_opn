#!/bin/sh
# Cleanup script for GameControl plugin in OPNsense

echo "Iniciando desinstalación completa y limpieza absoluta de GameControl..."

# 1. Detener servicios y tareas relacionadas
/usr/local/sbin/configctl service reload all >/dev/null 2>&1

# 2. Restaurar /var/unbound/unbound.conf eliminando cualquier include de gamecontrol
if [ -f /var/unbound/unbound.conf ]; then
    sed -i '' '/gamecontrol/d' /var/unbound/unbound.conf
fi

# 3. Eliminar archivos de reglas y modelos del plugin
rm -rf /usr/local/opnsense/mvc/app/models/OPNsense/GameControl
rm -rf /usr/local/opnsense/mvc/app/views/OPNsense/GameControl
rm -rf /usr/local/opnsense/mvc/app/controllers/OPNsense/GameControl
rm -rf /usr/local/opnsense/scripts/OPNsense/GameControl
rm -f /usr/local/opnsense/service/conf/actions.d/actions_gamecontrol.conf
rm -f /var/unbound/etc/gamecontrol.conf
rm -f /usr/local/etc/unbound/unbound.conf.d/gamecontrol.conf
rm -f /var/etc/gamecontrol_unblocked.json

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


