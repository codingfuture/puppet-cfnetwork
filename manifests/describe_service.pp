
define cfnetwork::describe_service(
    $server,
    $client = 'default',
) {
    @cfnetwork_firewall_service { $title:
        ensure => present,
        server_ports => $server,
        client_ports => $client,
    }
}