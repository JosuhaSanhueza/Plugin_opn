#!/usr/bin/env python3
import os, json, datetime, urllib.request, urllib.parse, re

UNBLOCKED_FILE = "/var/etc/gamecontrol_unblocked.json"
LOG_FILE = "/var/log/gamecontrol.log"
ADGUARD_API_URL = "http://127.0.0.1:3000/control"

def log_msg(msg):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    formatted = "[" + timestamp + "] " + str(msg) + "\n"
    print(formatted.strip())
    try:
        with open(LOG_FILE, "a") as f:
            f.write(formatted)
    except Exception:
        pass

def update_game_control():
    log_msg("Sincronizando clientes persistentes en AdGuardHome.yaml...")

    unblocked_ips = set()
    if os.path.exists(UNBLOCKED_FILE):
        try:
            with open(UNBLOCKED_FILE, "r") as f:
                data = json.load(f)
                if isinstance(data, dict):
                    for ip, st in data.items():
                        if st == 0:
                            unblocked_ips.add(ip)
                elif isinstance(data, list):
                    for ip in data:
                        unblocked_ips.add(str(ip))
        except Exception as e:
            log_msg("Error leyendo unblocked file: " + str(e))

    log_msg("IPs de Alumnos con juegos habilitados: " + str(len(unblocked_ips)))

    # Escribir la lista de clientes persistentes directamente en AdGuardHome.yaml
    clients_yaml_lines = ["clients:", "  persistent:"]
    for i in range(101, 146):
        ip_addr = "192.168.12." + str(i)
        hostname = "Lab2-" + str(i - 100)
        is_allowed = ip_addr in unblocked_ips
        clients_yaml_lines.append("    - name: \"" + hostname + "\"")
        clients_yaml_lines.append("      ids:")
        clients_yaml_lines.append("        - \"" + ip_addr + "\"")
        clients_yaml_lines.append("      use_global_settings: false")
        clients_yaml_lines.append("      filtering_enabled: " + ("false" if is_allowed else "true"))
        clients_yaml_lines.append("      parental_enabled: false")
        clients_yaml_lines.append("      safesearch_enabled: false")
        clients_yaml_lines.append("      use_global_blocked_services: true")
        clients_yaml_lines.append("      blocked_services: []")

    clients_str = "\n".join(clients_yaml_lines) + "\n"

    for yaml_path in ["/usr/local/bin/AdGuardHome.yaml", "/var/db/adguardhome/AdGuardHome.yaml", "/usr/local/etc/adguardhome/AdGuardHome.yaml", "/var/adguardhome/AdGuardHome.yaml"]:
        if os.path.exists(yaml_path):
            try:
                with open(yaml_path, "r") as f:
                    content = f.read()
                if "clients:" in content:
                    new_content = re.sub(r"clients:.*?(?=\n\w|\Z)", clients_str.strip(), content, flags=re.DOTALL)
                else:
                    new_content = content + "\n" + clients_str
                with open(yaml_path, "w") as f:
                    f.write(new_content)
                log_msg("Clientes Persistentes actualizados exitosamente en " + yaml_path + ". Recargando AdGuard...")
                os.system("/usr/local/bin/AdGuardHome -s restart >/dev/null 2>&1 || service adguardhome restart >/dev/null 2>&1 || pkill -HUP AdGuardHome >/dev/null 2>&1")
                break
            except Exception as ex:
                log_msg("Error escribiendo clientes en " + yaml_path + ": " + str(ex))

if __name__ == "__main__":
    update_game_control()
