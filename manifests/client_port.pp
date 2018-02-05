#
# Copyright 2016-2018 (c) Andrey Galkin
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
            tag           => [$cfnetwork::location, $cfnetwork::location_pool],
            hostname      => $::trusted['certname'],
            location      => $cfnetwork::location,
            location_pool => $cfnetwork::location_pool,
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
    cfnetwork::internal::fetch_hosts { "client:${title}":
        src    => $src,
        dst    => $dst,
        before => Anchor['cfnetwork:pre-firewall'],
    }
}
