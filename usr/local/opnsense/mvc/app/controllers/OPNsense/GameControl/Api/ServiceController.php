<<?php

namespace OPNsense\GameControl\Api;

use OPNsense\Base\ApiControllerBase;
use OPNsense\Core\Backend;
use OPNsense\Core\Config;

class ServiceController extends ApiControllerBase
{
    public function getHostsAction()
    {
        $ipStart = $this->request->get("ip_start", null, "192.168.12.101");
        $ipEnd = $this->request->get("ip_end", null, "192.168.12.145");

        $ipStartLong = ip2long($ipStart);
        $ipEndLong = ip2long($ipEnd);

        $unblockedIps = array();
        $unblockedFile = "/var/etc/gamecontrol_unblocked.json";
        if (file_exists($unblockedFile)) {
            $unblockedIps = json_decode(file_get_contents($unblockedFile), true) ?: array();
        }

        $hosts = array();
        $config = Config::getInstance()->object();

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

        $leasesFile = "/var/dhcpd/var/db/dhcpd.leases";
        if (file_exists($leasesFile)) {
            $content = file_get_contents($leasesFile);
            preg_match_all("/lease\s+([0-9\.]+)\s*\{[^}]*hardware\s+ethernet\s+([0-9a-f:]+);/i", $content, $matches, PREG_SET_ORDER);
            foreach ($matches as $m) {
                $ip = $m[1];
                $ipLong = ip2long($ip);
                if ($ipLong !== false && $ipLong >= $ipStartLong && $ipLong <= $ipEndLong && !isset($hosts[$ip])) {
                    $isBlocked = isset($unblockedIps[$ip]) && $unblockedIps[$ip] == 0 ? 0 : 1;
                    $hosts[$ip] = array(
                        "hostname" => "Host-" . str_replace(".", "-", $ip),
                        "ip" => $ip,
                        "ip_long" => $ipLong,
                        "mac" => $m[2],
                        "blocked" => $isBlocked
                    );
                }
            }
        }

        $hostList = array_values($hosts);
        usort($hostList, function($a, $b) {
            return $a["ip_long"] <=> $b["ip_long"];
        });

        return array("status" => "ok", "hosts" => $hostList, "ip_start" => $ipStart, "ip_end" => $ipEnd);
    }

    public function toggleHostAction($ip = null, $status = null)
    {
        if ($ip === null) {
            $ip = $this->request->getPost("ip", null, $this->request->get("ip"));
        }
        if ($status === null) {
            $status = $this->request->getPost("status", null, $this->request->get("status"));
        }

        if (!empty($ip) && $status !== null) {
            $unblockedFile = "/var/etc/gamecontrol_unblocked.json";
            $unblockedIps = array();
            if (file_exists($unblockedFile)) {
                $raw = file_get_contents($unblockedFile);
                $decoded = json_decode($raw, true);
                if (is_array($decoded)) {
                    foreach ($decoded as $k => $v) {
                        if (is_numeric($k)) {
                            $unblockedIps[$v] = 0;
                        } else {
                            $unblockedIps[$k] = $v;
                        }
                    }
                }
            }

            if ((int)$status == 0) {
                $unblockedIps[$ip] = 0;
            } else {
                unset($unblockedIps[$ip]);
            }

            file_put_contents($unblockedFile, json_encode($unblockedIps));

            $backend = new Backend();
            $response = $backend->configdRun("gamecontrol reload");
            return array("status" => "ok", "ip" => $ip, "blocked" => (int)$status, "backend" => $response);
        }

        return array("status" => "error", "message" => "Faltan parámetros");
    }

    public function setAllAction()
    {
        $status = $this->request->getPost("status", null, $this->request->get("status"));
        $ipStart = $this->request->getPost("ip_start", null, $this->request->get("ip_start", null, "192.168.12.101"));
        $ipEnd = $this->request->getPost("ip_end", null, $this->request->get("ip_end", null, "192.168.12.145"));

        $unblockedFile = "/var/etc/gamecontrol_unblocked.json";
        $unblockedIps = array();

        if ((int)$status == 0) {
            $ipStartLong = ip2long($ipStart);
            $ipEndLong = ip2long($ipEnd);
            if ($ipStartLong !== false && $ipEndLong !== false) {
                for ($i = $ipStartLong; $i <= $ipEndLong; $i++) {
                    $unblockedIps[long2ip($i)] = 0;
                }
            }
        } else {
            $unblockedIps = array();
        }

        file_put_contents($unblockedFile, json_encode($unblockedIps));

        $backend = new Backend();
        $response = $backend->configdRun("gamecontrol reload");

        return array("status" => "ok", "blocked" => (int)$status, "backend" => $response);
    }

    public function restartServiceAction()
    {
        $backend = new Backend();
        $responseRules = $backend->configdRun("gamecontrol reload");
        return array(
            "status" => "ok",
            "message" => "Servicio de control de juegos sincronizado exitosamente.",
            "response_rules" => $responseRules
        );
    }

    public function getLogsAction()
    {
        $logFile = "/var/log/gamecontrol.log";
        $logContent = file_exists($logFile) ? file_get_contents($logFile) : "No hay registros disponibles.";

        $lines = explode("\n", trim($logContent));
        $recentLines = array_slice($lines, -40);

        $unblockedFile = "/var/etc/gamecontrol_unblocked.json";
        $unblockedContent = file_exists($unblockedFile) ? file_get_contents($unblockedFile) : "{}";

        return array(
            "status" => "ok",
            "logs" => implode("\n", $recentLines),
            "unblocked_ips" => json_decode($unblockedContent, true) ?: array()
        );
    }
}
