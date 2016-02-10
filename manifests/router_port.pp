define cfnetwork::router_port (
    # $title = "inface/outface:service"
    $src= undef,
    $dst = undef,
    $comment = undef,
) {
    @@cfnetwork::internal::exported_port { "${::fqdn}:router:${title}":
        src=> $src,
        dst => $dst,
        comment => $comment,
        tag => [$::cf_location, $::cf_location_pool],
    }
    @cfnetwork_firewall_port { "router:${title}":
        ensure => present,
        src => $src,
        dst => $dst,
        comment => $comment,
    }
}
