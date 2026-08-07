<script>
    $(document).ready(function() {
        loadStudentHosts();

        $('#filter-form').on('submit', function(e) {
            e.preventDefault();
            loadStudentHosts();
        });
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

<div class="content-box" style="border-radius: 6px; padding: 20px; margin-bottom: 30px;">
    <div class="row">
        <div class="col-md-7">
            <h2 style="margin-top:0; font-weight: 600;">Escolarapp Game Manager</h2>
            <p class="text-muted">Control Modular de Juegos (Unbound/DNSBL + DNSMasq) por cada PC/Estudiante.</p>
        </div>
        <div class="col-md-5 text-right">
            <button class="btn btn-danger" style="font-weight: bold; padding: 8px 16px; margin-right: 8px;" onclick="toggleAll(1)">
                <i class="fa fa-lock"></i> Bloquear Todos
            </button>
            <button class="btn btn-info" style="font-weight: bold; padding: 8px 16px; background-color: #0288d1; border:none;" onclick="toggleAll(0)">
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


