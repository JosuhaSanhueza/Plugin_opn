#!/usr/bin/env python3
import os
import json
import datetime

UNBLOCKED_FILE = '/var/etc/gamecontrol_unblocked.json'
ALLOWED_IPS_FILE = '/var/etc/gamecontrol_allowed_ips.txt'
LOG_FILE = '/var/log/gamecontrol.log'

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
    log_msg("Iniciando actualización de tabla PF GameControl...")

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

    allowed_list = sorted(list(unblocked_ips))
    log_msg(f"IPs con juegos habilitados (Exención NAT): {len(allowed_list)}")

    os.makedirs(os.path.dirname(ALLOWED_IPS_FILE), exist_ok=True)
    with open(ALLOWED_IPS_FILE, 'w') as f:
        f.write("\n".join(allowed_list) + "\n" if allowed_list else "")

    # Actualización instantánea en el Cortafuegos de FreeBSD (PF Table)
    os.system(f'/sbin/pfctl -t game_allowed_ips -T replace -f {ALLOWED_IPS_FILE} >/dev/null 2>&1')
    log_msg("Sincronización instantánea de tabla PF (game_allowed_ips) ejecutada exitosamente.")

if __name__ == '__main__':
    update_game_control()






