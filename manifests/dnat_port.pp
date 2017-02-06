#
# Copyright 2016-2017 (c) Andrey Galkin
#


# Please see README
define cfnetwork::dnat_port (
    # $title = "inface/outface:service[:optionalTag]"
    Optional[Variant[Array[String[1]], String[1]]]
        $src = undef,
    Optional[Variant[Array[String[1]], String[1]]]
        $dst = undef,
    Optional[String[1]]
        $to_dst = undef,
    Optional[Integer[1, 65535]]
        $to_port = undef,
    Optional[String[1]]
        $comment = undef,
) {
    if $::cfnetwork::export_resources {
        @@cfnetwork::internal::exported_port { "${::fqdn}:dnat:${title}":
            src           => $src,
            dst           => $dst,
            to_dst        => $to_dst,
            to_port       => $to_port,
            comment       => $comment,
            tag           => [$::cf_location, $::cf_location_pool],
            hostname      => $::trusted['certname'],
            location      => $::cf_location,
            location_pool => $::cf_location_pool,
        }
    }
    @cfnetwork_firewall_port { "dnat:${title}":
        ensure  => present,
        src     => $src,
        dst     => $dst,
        to_dst  => $to_dst,
        to_port => $to_port,
        comment => $comment,
    }
    cfnetwork::internal::fetch_hosts { "dnat:${title}":
        src    => $src,
        dst    => $dst,
        to_dst => $to_dst,
        before => Anchor['cfnetwork:pre-firewall'],
    }

    if $to_port {
        $title_split = split($title, ':')
        $iface = $title_split[0]
        $orig_service = $title_split[1]

        # provider will auto-define one
        # TODO: use stdlib to get proto from the original service
        #       to define this DNATed service here
        $service = "${orig_service}_${to_port}"
        cfnetwork::router_port { "${iface}:${service}":
            src => $src,
            dst => $to_dst,
        }
    } else {
        cfnetwork::router_port { $title:
            src => $src,
            dst => $to_dst,
        }
    }
}
