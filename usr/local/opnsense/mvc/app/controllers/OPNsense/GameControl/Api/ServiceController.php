<?php

namespace OPNsense\GameControl\Api;

use OPNsense\Base\ApiControllerBase;
use OPNsense\Core\Backend;
use OPNsense\Core\Config;

class ServiceController extends ApiControllerBase
{
    public function getHostsAction()
    {
        $ipStart = $this->request->get('ip_start', null, '192.168.12.101');
        $ipEnd = $this->request->get('ip_end', null, '192.168.12.145');

        $ipStartLong = ip2long($ipStart);
        $ipEndLong = ip2long($ipEnd);

        // Cargar estado de IPs desbloqueadas desde el archivo de persistencia
        $unblockedIps = array();
        $unblockedFile = '/var/etc/gamecontrol_unblocked.json';
        if (file_exists($unblockedFile)) {
            $unblockedIps = json_decode(file_get_contents($unblockedFile), true) ?: array();
        }

        $hosts = array();
        $config = Config::getInstance()->object();

        // 1. Obtener Hosts estáticos de Dnsmasq
        if (isset($config->dnsmasq) && isset($config->dnsmasq->hosts)) {
            foreach ($config->dnsmasq->hosts as $host) {
                if (!empty($host->ip)) {
                    $ip = (string)$host->ip;
                    $ipLong = ip2long($ip);
                    if ($ipLong !== false && $ipLong >= $ipStartLong && $ipLong <= $ipEndLong) {
                        $isBlocked = isset($unblockedIps[$ip]) && $unblockedIps[$ip] == 0 ? 0 : 1;
                        $hosts[$ip] = array(
                            "hostname" => !empty($host->host) ? (string)$host->host : "Sin Nombre",
                            "ip" => $ip,
                            "ip_long" => $ipLong,
                            "mac" => !empty($host->mac) ? (string)$host->mac : "-",
                            "blocked" => $isBlocked
                        );
                    }
                }
            }
        }

        // 2. Obtener Arrendamientos de DHCP (DHCP Leases)
        $leasesFile = '/var/dhcpd/var/db/dhcpd.leases';
        if (file_exists($leasesFile)) {
            $content = file_get_contents($leasesFile);
            preg_match_all('/lease\s+([0-9\.]+)\s*\{[^}]*hardware\s+ethernet\s+([0-9a-f:]+);[^}]*(?:client-hostname\s+"([^"]+)";)?/i', $content, $matches, PREG_SET_ORDER);
            foreach ($matches as $m) {
                $ip = $m[1];
                $ipLong = ip2long($ip);
                if ($ipLong !== false && $ipLong >= $ipStartLong && $ipLong <= $ipEndLong && !isset($hosts[$ip])) {
                    $isBlocked = isset($unblockedIps[$ip]) && $unblockedIps[$ip] == 0 ? 0 : 1;
                    $hosts[$ip] = array(
                        "hostname" => !empty($m[3]) ? $m[3] : "Host-" . str_replace('.', '-', $ip),
                        "ip" => $ip,
                        "ip_long" => $ipLong,
                        "mac" => $m[2],
                        "blocked" => $isBlocked
                    );
                }
            }
        }

        // 3. Ordenar ascendentemente por IP (de menor a mayor)
        $hostList = array_values($hosts);
        usort($hostList, function($a, $b) {
            return $a['ip_long'] <=> $b['ip_long'];
        });

        return array("status" => "ok", "hosts" => $hostList, "ip_start" => $ipStart, "ip_end" => $ipEnd);
    }

    public function toggleHostAction($ip = null, $status = null)
    {
        if ($ip !== null && $status !== null) {
            $unblockedFile = '/var/etc/gamecontrol_unblocked.json';
            $unblockedIps = array();
            if (file_exists($unblockedFile)) {
                $unblockedIps = json_decode(file_get_contents($unblockedFile), true) ?: array();
            }

            if ((int)$status == 0) {
                // Desbloquear (Juegos Permitidos)
                $unblockedIps[$ip] = 0;
            } else {
                // Bloquear (Juegos Bloqueados)
                unset($unblockedIps[$ip]);
            }

            $backend = new Backend();
            $response = $backend->configdRun("gamecontrol reload");
            return array("status" => "ok", "ip" => $ip, "blocked" => (int)$status, "backend" => $response);
        }

        return array("status" => "error", "message" => "Faltan parámetros");
    }

    public function restartServiceAction()

    {
        $backend = new Backend();
        $responseRules = $backend->configdRun("gamecontrol reload");
        $responseUnbound = $backend->configdRun("unbound restart");
        return array(
            "status" => "ok",
            "message" => "Servicio de control de juegos reseteado y Unbound re-sincronizado exitosamente.",
            "response_rules" => $responseRules,
            "response_unbound" => $responseUnbound
        );
    }

    public function getLogsAction()
    {
        $logFile = '/var/log/gamecontrol.log';
        $logContent = file_exists($logFile) ? file_get_contents($logFile) : "No hay registros disponibles.";

        $lines = explode("\n", trim($logContent));
        $recentLines = array_slice($lines, -40);

        $unblockedFile = '/var/etc/gamecontrol_unblocked.json';
        $unblockedContent = file_exists($unblockedFile) ? file_get_contents($unblockedFile) : "{}";

        return array(
            "status" => "ok",
            "logs" => implode("\n", $recentLines),
            "unblocked_ips" => json_decode($unblockedContent, true) ?: array()
        );
    }
}


