#
# Copyright 2016-2018 (c) Andrey Galkin
#


# Please see README
define cfnetwork::describe_service (
    Variant[String[1], Array[String[1]]]
        $server,
    Variant[String[1], Array[String[1]]]
        $client = 'default',
    Optional[String[1]]
        $comment = undef,
) {
    @cfnetwork_firewall_service { $title:
        ensure       => present,
        server_ports => $server,
        client_ports => $client,
        comment      => $comment,
    }
}
