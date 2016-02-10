define cfnetwork::service_port (
    # $title = "iface:service"
    $src= undef,
    $dst = undef,
    $comment = undef,
) {
    if $::cfnetwork::export_resources {
        @@cfnetwork::internal::exported_port { "${::fqdn}:service:${title}":
            src=> $src,
            dst => $dst,
            comment => $comment,
            tag => [$::cf_location, $::cf_location_pool],
        }
    }
    @cfnetwork_firewall_port { "service:${title}":
        ensure => present,
        src => $src,
        dst => $dst,
        comment => $comment,
    }
}
