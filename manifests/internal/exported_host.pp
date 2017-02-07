#
# Copyright 2016-2017 (c) Andrey Galkin
#


# Please see README
define cfnetwork::internal::exported_host (
    # $title = "hostname"
    $host_aliases,
    $ip,
    $location, # = $cfnetwork::location
    $location_pool, # = $cfnetwork::location_pool
) {
    if $title != $::trusted['certname'] and !defined(Host[$title]) {
        host { $title:
            host_aliases => $host_aliases,
            ip           => $ip,
            before       => Anchor['cfnetwork:pre-firewall'],
        }

        if $cfnetwork::local_dns {
            Host[$title] ~> Service[$cfnetwork::dns_service_name]
        }
    }
}
