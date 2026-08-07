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

        $hosts = array();
        $config = Config::getInstance()->object();

        // 1. Obtener Hosts estáticos de Dnsmasq
        if (isset($config->dnsmasq) && isset($config->dnsmasq->hosts)) {
            foreach ($config->dnsmasq->hosts as $host) {
                if (!empty($host->ip)) {
                    $ip = (string)$host->ip;
                    $ipLong = ip2long($ip);
                    if ($ipLong !== false && $ipLong >= $ipStartLong && $ipLong <= $ipEndLong) {
                        $hosts[$ip] = array(
                            "hostname" => !empty($host->host) ? (string)$host->host : "Sin Nombre",
                            "ip" => $ip,
                            "ip_long" => $ipLong,
                            "mac" => !empty($host->mac) ? (string)$host->mac : "-",
                            "blocked" => 1
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
                    $hosts[$ip] = array(
                        "hostname" => !empty($m[3]) ? $m[3] : "Host-" . str_replace('.', '-', $ip),
                        "ip" => $ip,
                        "ip_long" => $ipLong,
                        "mac" => $m[2],
                        "blocked" => 1
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


    public function reloadAction()
    {
        $backend = new Backend();
        $response = $backend->configdRun("gamecontrol reload");
        return array("status" => "ok", "response" => $response);
    }

    public function toggleHostAction($ip, $status)
    {
        $backend = new Backend();
        $response = $backend->configdRun("gamecontrol reload");
        return array("status" => "ok", "ip" => $ip, "blocked" => $status);
    }
}

