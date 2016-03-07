define cfnetwork::client_port (
    # $title = "iface:service[:optionalTag]"
    $src = undef,
    $dst = undef,
    $user = undef,
    $group = undef,
    $comment = undef,
) {
    if $::cfnetwork::export_resources {
        @@cfnetwork::internal::exported_port { "${::fqdn}:client:${title}":
            src     => $src,
            dst     => $dst,
            user    => $user,
            group   => $group,
            comment => $comment,
            tag     => [$::cf_location, $::cf_location_pool],
            hostname => $::trusted['certname'],
            location => $::cf_location,
            location_pool => $::cf_location_pool,
        }
    }
    @cfnetwork_firewall_port { "client:${title}":
        ensure  => present,
        src     => $src,
        dst     => $dst,
        user    => $user,
        group   => $group,
        comment => $comment,
    }
}
