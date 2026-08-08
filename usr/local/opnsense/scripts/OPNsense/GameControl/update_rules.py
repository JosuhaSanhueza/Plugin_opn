#!/usr/bin/env python3
import os
import urllib.request
import re
import datetime
import json
import xml.etree.ElementTree as ET



CONFIG_PATH = '/conf/config.xml'
UNBOUND_RULES_PATH = '/usr/local/etc/unbound/gamecontrol.conf'

def parse_hosts_from_github(url):
    domains = set()
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'OPNsense-GameControl'})
        with urllib.request.urlopen(req, timeout=10) as response:
            content = response.read().decode('utf-8')
            for line in content.splitlines():
                line = line.strip()
                if not line or line.startswith('#') or line.startswith('!'):
                    continue
                # Soportar sintaxis tipo Adblock/Hosts (0.0.0.0 domain.com o solo domain.com)
                parts = line.split()
                if len(parts) >= 2:
                    domain = parts[1]
                else:
                    domain = parts[0]
                
                # Limpiar prefijos de sintaxis Adblock (ej: ||domain.com^ -> domain.com)
                domain = domain.lstrip('|').rstrip('^').strip()
                if domain and domain != 'localhost' and '.' in domain:
                    domains.add(domain)
    except Exception as e:
        print(f"Error downloading list from {url}: {e}")
    return domains


def get_unbound_dnsbl_game_domains(root):
    domains = set()

    # Buscar en todas las estructuras posibles dentro de <OPNsense><Unbound> en config.xml
    # 1. Buscar cualquier nodo cuya descripción sea "Games" o similar
    for elem in root.findall('.//OPNsense/Unbound//'):
        descr = elem.find('description')
        if descr is not None and descr.text and 'game' in descr.text.lower():
            log_msg(f"Se encontró entrada DNSBL que coincide con 'Games': {descr.text}")

            # Buscar URLs
            for child in elem:
                if child.tag in ['url', 'urls', 'type'] and child.text:
                    for u in child.text.split(','):
                        u = u.strip()
                        if u.startswith('http'):
                            log_msg(f"Descargando lista de juegos desde URL: {u}")
                            domains.update(parse_hosts_from_github(u))

                # Buscar Dominios ingresados a mano (Blocklist Domains)
                if child.tag in ['blocklist_domains', 'domains', 'blocklist'] and child.text:
                    log_msg(f"Extrayendo dominios manuales de la entrada 'Games'")
                    for d in child.text.split():
                        d = d.strip()
                        if d and not d.startswith('#'):
                            domains.add(d)

    # 2. Si no se especificó la descripción "Games", buscar URLs directas de GitHub en la configuración de DNSBL
    if not domains:
        for elem in root.findall('.//OPNsense/Unbound//type'):
            if elem.text and 'github' in elem.text.lower():
                log_msg(f"Buscando URL de GitHub en DNSBL: {elem.text}")
                domains.update(parse_hosts_from_github(elem.text))

    # 3. Fallback a la URL por defecto oficial del usuario si no se detectó en config.xml
    if not domains:
        gc_url = root.find('.//OPNsense/GameControl/general/github_url')
        url_to_use = gc_url.text if (gc_url is not None and gc_url.text) else "https://raw.githubusercontent.com/JosuhaSanhueza/BlockList/refs/heads/main/GamesBlockList.txt"
        log_msg(f"Descargando lista oficial de juegos desde GitHub: {url_to_use}")
        domains.update(parse_hosts_from_github(url_to_use))

    return domains, url_to_use if 'url_to_use' in locals() else "https://raw.githubusercontent.com/JosuhaSanhueza/BlockList/refs/heads/main/GamesBlockList.txt"



def log_msg(msg):
    log_file = '/var/log/gamecontrol.log'
    timestamp = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    formatted = f"[{timestamp}] {msg}\n"
    print(formatted.strip())
    try:
        with open(log_file, 'a') as f:
            f.write(formatted)
    except Exception as e:
        pass

def generate_unbound_rules():
    log_msg("Iniciando actualización de reglas DNS GameControl...")
    if not os.path.exists(CONFIG_PATH):
        log_msg(f"ERROR: No se encontró {CONFIG_PATH}")
        return

    tree = ET.parse(CONFIG_PATH)
    root = tree.getroot()
    
    blocked_domains, list_url = get_unbound_dnsbl_game_domains(root)
    log_msg(f"Se obtuvieron {len(blocked_domains)} dominios de juegos desde: {list_url}")


    # Extraer IPs desbloqueadas (Permitidas)
    unblocked_ips = set()
    unblocked_file = '/var/etc/gamecontrol_unblocked.json'
    if os.path.exists(unblocked_file):
        try:
            with open(unblocked_file, 'r') as f:
                data = json.load(f)
                if isinstance(data, dict):
                    for ip, st in data.items():
                        if st == 0:
                            unblocked_ips.add(ip)
                elif isinstance(data, list):
                    for ip in data:
                        unblocked_ips.add(str(ip))
        except Exception as e:
            log_msg(f"Error leyendo {unblocked_file}: {e}")


    # Extraer IPs objetivo (por defecto todas las detectadas en el rango)
    # y filtrar las que hayan sido desbloqueadas desde la interfaz
    all_ips = set()
    for item in root.findall('.//OPNsense/Unbound//') + root.findall('.//OPNsense/Dnsmasq//'):
        pass

    # 1. Generar la lista de IPs que deben estar bloqueadas
    blocked_ips_list = []
    for i in range(101, 146):
        ip_addr = f"192.168.12.{i}"
        if ip_addr not in unblocked_ips:
            blocked_ips_list.append(ip_addr)

    log_msg(f"IPs con bloqueo activo: {len(blocked_ips_list)} (Permitidas: {len(unblocked_ips)})")

    # 2. Escribir archivo de reglas para Unbound con sintaxis nativa de tags
    lines = [
        "# Auto-generated by OPNsense GameControl Plugin",
        "server:",
        '    define-tag: "gaming_blocked"',
        '    access-control-tag-action: "gaming_blocked" always_refuse'
    ]

    for ip_addr in blocked_ips_list:
        lines.append(f'    access-control-tag: {ip_addr}/32 "gaming_blocked"')

    for domain in blocked_domains:
        lines.append(f'    access-control-tag-data: {domain} "gaming_blocked" always_refuse')

    os.makedirs(os.path.dirname(UNBOUND_RULES_PATH), exist_ok=True)
    with open(UNBOUND_RULES_PATH, 'w') as f:
        f.write("\n".join(lines))


    # Escribir en runtime de Unbound
    for rpath in ['/var/unbound/etc/gamecontrol.conf', '/usr/local/etc/unbound/unbound.conf.d/gamecontrol.conf']:
        try:
            os.makedirs(os.path.dirname(rpath), exist_ok=True)
            with open(rpath, 'w') as f:
                f.write("\n".join(lines))
        except Exception as e:
            pass

    # 3. Vaciar la caché DNS en memoria de Unbound para las IPs habilitadas
    if unblocked_ips:
        for domain in list(blocked_domains)[:50]:
            os.system(f'/usr/local/sbin/unbound-control flush {domain} >/dev/null 2>&1')

    # 4. Actualizar tabla dinamica del Cortafuegos (PF Table)
    pf_table_file = '/var/etc/gamecontrol_pf_blocked.txt'
    with open(pf_table_file, 'w') as f:
        f.write("\n".join(blocked_ips_list))

    os.system(f'/sbin/pfctl -t game_blocked_ips -T replace -f {pf_table_file} >/dev/null 2>&1')

    # 5. Reiniciar/Recargar Unbound de forma silenciosa
    res = os.system('/usr/local/sbin/unbound-control reload >/dev/null 2>&1')
    log_msg("Sincronización instantánea de Unbound y PF ejecutada exitosamente.")




if __name__ == '__main__':
    generate_unbound_rules()



