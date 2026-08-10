<script>
    $(document).ready(function() {
        loadStudentHosts();

        $('#filter-form').on('submit', function(e) {
            e.preventDefault();
            loadStudentHosts();
        });

        // Cambio de pestañas
        $('#gamecontrol-tabs a').click(function (e) {
            e.preventDefault();
            $(this).tab('show');
        });

        if (window.location.hash === '#guide') {
            $('#gamecontrol-tabs a[href="#tab-guide"]').tab('show');
        }
    });

    function loadStudentHosts() {
        var ipStart = $('#ip_start').val() || '192.168.12.101';
        var ipEnd = $('#ip_end').val() || '192.168.12.145';

        $('#student-list').html('<tr><td colspan="4" class="text-center"><i class="fa fa-spinner fa-spin"></i> Cargando equipos en rango ' + ipStart + ' - ' + ipEnd + '...</td></tr>');

        $.getJSON('/api/gamecontrol/service/getHosts', { ip_start: ipStart, ip_end: ipEnd }, function(data) {
            if (data && data.hosts) {
                var html = '';
                if (data.hosts.length === 0) {
                    html = '<tr><td colspan="4" class="text-center text-muted">No se encontraron equipos en este rango de IP.</td></tr>';
                } else {
                    $.each(data.hosts, function(i, host) {
                        var isBlocked = host.blocked == 1;
                        var badgeStyle = isBlocked ? 'background-color: #c9302c; color: #fff;' : 'background-color: #0088cc; color: #fff;';
                        var statusText = isBlocked ? 'Juegos Bloqueados 🚫' : 'Juegos Permitidos 🎮';
                        var btnStyle = isBlocked ? 'background-color: #28a745; color: #fff; border: none;' : 'background-color: #d9534f; color: #fff; border: none;';
                        var btnIcon = isBlocked ? 'fa-unlock' : 'fa-lock';
                        var btnText = isBlocked ? 'Habilitar Juegos' : 'Bloquear Juegos';
                        var nextState = isBlocked ? 0 : 1;

                        html += '<tr>';
                        html += '<td style="vertical-align: middle;"><strong>' + host.hostname + '</strong></td>';
                        html += '<td style="vertical-align: middle;"><span style="font-size:14px; font-weight: bold; color:#ffd54f; font-family: monospace;">' + host.ip + '</span> <small style="color:#888;">(' + host.mac + ')</small></td>';
                        html += '<td style="vertical-align: middle;"><span class="badge" style="' + badgeStyle + ' font-size: 12px; padding: 6px 12px; border-radius: 4px;">' + statusText + '</span></td>';
                        html += '<td style="vertical-align: middle;">';
                        html += '<button class="btn btn-xs" style="' + btnStyle + ' font-weight: 600; padding: 6px 14px; border-radius: 4px;" onclick="toggleStudentGame(\'' + host.ip + '\', ' + nextState + ')">';
                        html += '<i class="fa ' + btnIcon + '"></i> ' + btnText;
                        html += '</button>';
                        html += '</td>';
                        html += '</tr>';
                    });
                }
                $('#student-list').html(html);
                $('#host-count').text(data.hosts.length);
            }
        });
    }

    function restartEmergencyService() {
        $('#student-list').html('<tr><td colspan="4" class="text-center text-warning"><i class="fa fa-refresh fa-spin"></i> Reiniciando Servicio DNS de Emergencia y Re-sincronizando reglas...</td></tr>');
        $.post('/api/gamecontrol/service/restartService', function(data) {
            loadStudentHosts();
        });
    }

    function toggleStudentGame(ip, blockState) {

        $.post('/api/gamecontrol/service/toggleHost/' + ip + '/' + blockState, function(data) {
            loadStudentHosts();
        });
    }

    function toggleAll(blockState) {
        $('#student-list tr button').each(function() {
            $(this).trigger('click');
        });
    }
</script>

<ul class="nav nav-tabs" id="gamecontrol-tabs" role="tablist" style="margin-bottom: 20px;">
    <li class="active"><a href="#tab-main" role="tab" data-toggle="tab"><i class="fa fa-gamepad"></i> Control Modular</a></li>
    <li><a href="#tab-guide" role="tab" data-toggle="tab"><i class="fa fa-book"></i> Guía de Configuración</a></li>
    <li><a href="#tab-debug" role="tab" data-toggle="tab" onclick="loadDebugLogs()"><i class="fa fa-bug"></i> Depurador & Logs</a></li>
</ul>


<div class="tab-content">
    <!-- PESTAÑA PRINCIPAL -->
    <div class="tab-pane active" id="tab-main">
        <div class="content-box" style="border-radius: 6px; padding: 20px; margin-bottom: 30px;">
            <div class="row">
                <div class="col-md-7">
                    <h2 style="margin-top:0; font-weight: 600;">Escolarapp Game Manager</h2>
                    <p class="text-muted">Control Modular de Juegos (Unbound/DNSBL + DNSMasq) por cada PC/Estudiante.</p>
                    <p style="font-size:12px;"><i class="fa fa-github"></i> Lista activa de GitHub: <a href="https://raw.githubusercontent.com/JosuhaSanhueza/BlockList/refs/heads/main/GamesBlockList.txt" target="_blank" style="color:#5bc0de; text-decoration:underline;">JosuhaSanhueza/BlockList (GamesBlockList.txt)</a></p>
                </div>
                <div class="col-md-5 text-right">
                    <button class="btn btn-warning" style="font-weight: bold; padding: 8px 14px; margin-right: 6px; background-color: #f0ad4e; color: #111; border:none;" onclick="restartEmergencyService()" title="Reiniciar Servicio y Re-sincronizar DNS en caso de atasco">
                        <i class="fa fa-refresh"></i> Reiniciar Servicio
                    </button>
                    <button class="btn btn-danger" style="font-weight: bold; padding: 8px 14px; margin-right: 6px;" onclick="toggleAll(1)">
                        <i class="fa fa-lock"></i> Bloquear Todos
                    </button>
                    <button class="btn btn-info" style="font-weight: bold; padding: 8px 14px; background-color: #0288d1; border:none;" onclick="toggleAll(0)">
                        <i class="fa fa-gamepad"></i> Habilitar Juegos a Todos
                    </button>
                </div>

            </div>


            <hr style="border-color: #333; margin: 15px 0 20px 0;">

            <!-- Filtro de Rango IP -->
            <div class="well well-sm" style="background-color: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.1); border-radius: 4px; padding: 12px 15px;">
                <form id="filter-form" class="form-inline">
                    <div class="form-group" style="margin-right: 15px;">
                        <label for="ip_start" style="margin-right: 8px;">IP Inicio:</label>
                        <input type="text" class="form-control input-sm" id="ip_start" value="192.168.12.101" style="width: 140px; text-align: center;">
                    </div>
                    <div class="form-group" style="margin-right: 15px;">
                        <label for="ip_end" style="margin-right: 8px;">IP Fin:</label>
                        <input type="text" class="form-control input-sm" id="ip_end" value="192.168.12.145" style="width: 140px; text-align: center;">
                    </div>
                    <button type="submit" class="btn btn-sm btn-primary" style="font-weight: 600;"><i class="fa fa-filter"></i> Aplicar Filtro Rango</button>
                    <span class="pull-right text-muted" style="margin-top: 5px;">Equipos encontrados: <strong id="host-count" style="color:#5bc0de;">0</strong></span>
                </form>
            </div>

            <!-- Tabla Ordenada -->
            <table class="table table-striped table-hover" style="margin-top: 15px;">
                <thead>
                    <tr>
                        <th>Hostname / Estudiante</th>
                        <th>IP / MAC</th>
                        <th>Estado DNS</th>
                        <th>Acción Rápida</th>
                    </tr>
                </thead>
                <tbody id="student-list">
                    <tr>
                        <td colspan="4" class="text-center"><i class="fa fa-spinner fa-spin"></i> Cargando...</td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>

    <!-- PESTAÑA GUÍA DE CONFIGURACIÓN -->
    <div class="tab-pane" id="tab-guide">
        <div class="content-box" style="border-radius: 6px; padding: 25px; margin-bottom: 30px;">
            <h2><i class="fa fa-cogs" style="color:#0288d1;"></i> Arquitectura AdGuard Home + Unbound (0 ms)</h2>
            <p class="text-muted">Filtrado granular por alumno vía API REST de AdGuard Home con resolución segura y cifrada en Unbound DoT (Puerto 5353).</p>

            <div class="row" style="margin-top: 25px;">
                <!-- PASO 1 -->
                <div class="col-md-4">
                    <div class="panel panel-default" style="background-color: rgba(255,255,255,0.03); border-color: #444;">
                        <div class="panel-heading" style="background-color: rgba(2,136,209,0.2); color:#fff; font-weight:bold;">
                            1. Unbound DNS (Puerto 5353)
                        </div>
                        <div class="panel-body">
                            <ul>
                                <li>En <strong>Servicios -> Unbound DNS -> General</strong>, cambie el puerto de escucha a <span style="color:#ffd54f; font-weight:bold;">5353</span>.</li>
                                <li>Mantiene intactas todas sus listas de seguridad (*Porno, Proxies, Updates, SpeedTest*) y su cifrado **DoT hacia Cloudflare (Puerto 853)**.</li>
                            </ul>
                        </div>
                    </div>
                </div>

                <!-- PASO 2 -->
                <div class="col-md-4">
                    <div class="panel panel-default" style="background-color: rgba(255,255,255,0.03); border-color: #444;">
                        <div class="panel-heading" style="background-color: rgba(40,167,69,0.2); color:#fff; font-weight:bold;">
                            2. AdGuard Home (Puerto 53)
                        </div>
                        <div class="panel-body">
                            <ul>
                                <li>Abrir la interfaz de AdGuard Home en <span style="color:#ffd54f; font-weight:bold;">http://192.168.12.1:3000</span>.</li>
                                <li>En <strong>Configuración -> Configuración DNS</strong>, coloque en Servidores Upstream:
                                    <br><span style="font-size:12px; color:#ffd54f; font-family:monospace;">127.0.0.1:5353</span>
                                </li>
                                <li>Desactive las listas de bloqueo globales en AdGuard para garantizar **0 latencia**.</li>
                            </ul>
                        </div>
                    </div>
                </div>

                <!-- PASO 3 -->
                <div class="col-md-4">
                    <div class="panel panel-default" style="background-color: rgba(255,255,255,0.03); border-color: #444;">
                        <div class="panel-heading" style="background-color: rgba(240,173,78,0.2); color:#fff; font-weight:bold;">
                            3. Plugin Escolarapp
                        </div>
                        <div class="panel-body">
                            <ul>
                                <li>Al presionar **"Habilitar Juegos"** en el panel web, el plugin envía una orden a la API REST de AdGuard en **0 milisegundos**.</li>
                                <li>El alumno habilitado juega al instante mientras Unbound mantiene la seguridad escolar activa para todos.</li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>

            <div class="row" style="margin-top: 10px;">
                <div class="col-md-12">
                    <div class="alert alert-info" style="background-color: rgba(2,136,209,0.1); border-color: #0288d1; color:#fff;">
                        <i class="fa fa-info-circle"></i> <strong>Integración 100% Nativa</strong>: Cero certificados instalados en PCs, cero interrupción de bancos o Zoom y logs detallados por cada equipo del laboratorio.
                    </div>
                </div>
            </div>

        </div>
    </div>




    <!-- PESTAÑA DEPURADOR Y LOGS -->
    <div class="tab-pane" id="tab-debug">
        <div class="content-box" style="border-radius: 6px; padding: 25px; margin-bottom: 30px;">
            <div class="row">
                <div class="col-md-9">
                    <h2><i class="fa fa-bug" style="color:#f0ad4e;"></i> Depurador del Sistema & Historial de Sincronización</h2>
                    <p class="text-muted">Registro en tiempo real de reglas DNS, estado de IPs habilitadas y respuestas de Unbound.</p>
                </div>
                <div class="col-md-3 text-right">
                    <button class="btn btn-default" onclick="loadDebugLogs()"><i class="fa fa-refresh"></i> Actualizar Logs</button>
                </div>
            </div>

            <div class="row" style="margin-top: 15px;">
                <div class="col-md-12">
                    <label>IPs Actualmente Habilitadas / Excluidas del Bloqueo:</label>
                    <pre id="unblocked-ips-view" style="background-color: #111; color: #5bc0de; font-size: 13px; font-family: monospace; border: 1px solid #333; height: 70px; padding: 10px;">Cargando...</pre>
                </div>
            </div>

            <div class="row" style="margin-top: 10px;">
                <div class="col-md-12">
                    <label>Últimas 40 Líneas de Registro (/var/log/gamecontrol.log):</label>
                    <pre id="log-output" style="background-color: #111; color: #8bc34a; font-size: 12px; font-family: monospace; border: 1px solid #333; height: 320px; overflow-y: scroll; padding: 10px;">Cargando registros...</pre>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
    function loadDebugLogs() {
        $.getJSON('/api/gamecontrol/service/getLogs', function(data) {
            if (data && data.logs) {
                $('#log-output').text(data.logs);
                var logsElement = document.getElementById("log-output");
                logsElement.scrollTop = logsElement.scrollHeight;
            }
            if (data && data.unblocked_ips) {
                $('#unblocked-ips-view').text(JSON.stringify(data.unblocked_ips, null, 2));
            }
        });
    }
</script>




