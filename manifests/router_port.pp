#
# Copyright 2016 (c) Andrey Galkin
#


# Please see README
define cfnetwork::router_port (
    # $title = "inface/outface:service"
    Optional[Variant[Array[String[1]], String[1]]]
        $src= undef,
    Optional[Variant[Array[String[1]], String[1]]]
        $dst = undef,
    Optional[String[1]]
        $comment = undef,
) {
    if $::cfnetwork::export_resources {
        @@cfnetwork::internal::exported_port { "${::fqdn}:router:${title}":
            src           => $src,
            dst           => $dst,
            comment       => $comment,
            tag           => [$::cf_location, $::cf_location_pool],
            hostname      => $::trusted['certname'],
            location      => $::cf_location,
            location_pool => $::cf_location_pool,
        }
    }
    @cfnetwork_firewall_port { "router:${title}":
        ensure  => present,
        src     => $src,
        dst     => $dst,
        comment => $comment,
    }
}
