#
# Copyright 2016-2017 (c) Andrey Galkin
#


# Please see README
define cfnetwork::client_port (
    # $title = "iface:service[:optionalTag]"
    Optional[Variant[Array[String[1]], String[1]]]
        $src = undef,
    Optional[Variant[Array[String[1]], String[1]]]
        $dst = undef,
    Optional[Variant[Array[String[1]], String[1]]]
        $user = undef,
    Optional[Variant[Array[String[1]], String[1]]]
        $group = undef,
    Optional[String[1]]
        $comment = undef,
) {
    if $::cfnetwork::export_resources {
        @@cfnetwork::internal::exported_port { "${::fqdn}:client:${title}":
            src           => $src,
            dst           => $dst,
            user          => $user,
            group         => $group,
            comment       => $comment,
            tag           => [$::cf_location, $::cf_location_pool],
            hostname      => $::trusted['certname'],
            location      => $::cf_location,
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
