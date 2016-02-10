define cfnetwork::dnat_port (
    # $title = "inface/outface:service[:optionalTag]"
    $src = undef,
    $dst = undef,
    $to_dst = undef,
    $to_port = undef,
    $comment = undef,
) {
    if $::cfnetwork::export_resources {
        @@cfnetwork::internal::exported_port { "${::fqdn}:dnat:${title}":
            src => $src,
            dst => $dst,
            to_dst => $to_dst,
            to_port => $to_port,
            comment => $comment,
            tag => [$::cf_location, $::cf_location_pool],
        }
    }
    @cfnetwork_firewall_port { "dnat:${title}":
        ensure => present,
        src => $src,
        dst => $dst,
        to_dst => $to_dst,
        to_port => $to_port,
        comment => $comment,
    }

    if $to_port {
        $title_split = split($title, ':')
        $iface = $title_split[0]
        $orig_service = $title_split[1]

        # provider will auto-define one
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
