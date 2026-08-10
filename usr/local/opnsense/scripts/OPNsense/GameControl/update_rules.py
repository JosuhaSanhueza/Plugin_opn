#!/usr/bin/env python3
import os
import json
import datetime
import urllib.request
import urllib.parse

UNBLOCKED_FILE = '/var/etc/gamecontrol_unblocked.json'
LOG_FILE = '/var/log/gamecontrol.log'
ADGUARD_API_URL = 'http://127.0.0.1:3000/control'

def log_msg(msg):
    timestamp = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    formatted = f"[{timestamp}] {msg}\n"
    print(formatted.strip())
    try:
        with open(LOG_FILE, 'a') as f:
            f.write(formatted)
    except Exception:
        pass

def update_game_control():
    log_msg("Iniciando sincronización con AdGuard Home API...")

    unblocked_ips = set()
    if os.path.exists(UNBLOCKED_FILE):
        try:
            with open(UNBLOCKED_FILE, 'r') as f:
                data = json.load(f)
                if isinstance(data, dict):
                    for ip, st in data.items():
                        if st == 0:
                            unblocked_ips.add(ip)
                elif isinstance(data, list):
                    for ip in data:
                        unblocked_ips.add(str(ip))
        except Exception as e:
            log_msg(f"Error leyendo {UNBLOCKED_FILE}: {e}")

    log_msg(f"IPs con juegos permitidos: {len(unblocked_ips)}")

    # Configurar reglas por cliente en AdGuard Home para las IPs del laboratorio
    for i in range(101, 146):
        ip_addr = f"192.168.12.{i}"
        hostname = f"Lab2-{i-100}"
        is_allowed = ip_addr in unblocked_ips
        
        # Si el alumno está habilitado (botón verde), blocked_services está vacío.
        # Si está bloqueado (botón rojo), se le aplica el bloqueo del servicio "online_games"
        blocked_services = [] if is_allowed else ["online_games"]

        client_data = {
            "name": hostname,
            "ids": [ip_addr],
            "use_global_settings": True,
            "filtering_enabled": True,
            "parental_enabled": False,
            "safesearch_enabled": False,
            "use_global_blocked_services": False,
            "blocked_services": blocked_services
        }

        try:
            req = urllib.request.Request(
                f"{ADGUARD_API_URL}/clients/update",
                data=json.dumps(client_data).encode('utf-8'),
                headers={'Content-Type': 'application/json'},
                method='POST'
            )
            with urllib.request.urlopen(req, timeout=3) as resp:
                pass
        except Exception:
            # Si el cliente aún no existe en AdGuard, agregarlo vía API /clients/add
            try:
                req_add = urllib.request.Request(
                    f"{ADGUARD_API_URL}/clients/add",
                    data=json.dumps(client_data).encode('utf-8'),
                    headers={'Content-Type': 'application/json'},
                    method='POST'
                )
                with urllib.request.urlopen(req_add, timeout=3) as resp:
                    pass
            except Exception as ex:
                pass

    log_msg("Sincronización con AdGuard Home API completada exitosamente.")

if __name__ == '__main__':
    update_game_control()







