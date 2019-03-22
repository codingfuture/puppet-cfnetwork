#
# Copyright 2016-2019 (c) Andrey Galkin
#


# Please see README
define cfnetwork::service_port (
    # $title = "iface:service"
    Optional[Variant[Array[String[1]], String[1]]]
        $src= undef,
    Optional[Variant[Array[String[1]], String[1]]]
        $dst = undef,
    Optional[String[1]]
        $comment = undef,
) {
    if $::cfnetwork::export_resources {
        @@cfnetwork::internal::exported_port { "${::fqdn}:service:${title}":
            src           => $src,
            dst           => $dst,
            comment       => $comment,
            tag           => [$cfnetwork::location, $cfnetwork::location_pool],
            hostname      => $::trusted['certname'],
            location      => $cfnetwork::location,
            location_pool => $cfnetwork::location_pool,
        }
    }
    @cfnetwork_firewall_port { "service:${title}":
        ensure  => present,
        src     => $src,
        dst     => $dst,
        comment => $comment,
    }
    cfnetwork::internal::fetch_hosts { "service:${title}":
        src    => $src,
        dst    => $dst,
        before => Anchor['cfnetwork:pre-firewall'],
    }
}
