
# Please see README
define cfnetwork::describe_service (
    $server,
    $client = 'default',
    $comment = undef,
) {
    @cfnetwork_firewall_service { $title:
        ensure       => present,
        server_ports => $server,
        client_ports => $client,
        comment      => $comment,
    }
}