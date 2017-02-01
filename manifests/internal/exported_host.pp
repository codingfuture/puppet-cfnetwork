#
# Copyright 2016-2017 (c) Andrey Galkin
#


# Please see README
define cfnetwork::internal::exported_host (
    # $title = "hostname"
    $host_aliases,
    $ip,
    $location, # = $::cf_location
    $location_pool, # = $::cf_location_pool
) {
    if $title != $::trusted['certname'] and !defined(Host[$title]) {
        host { $title:
            host_aliases => $host_aliases,
            ip           => $ip,
            notify       => Service[$cfnetwork::dns_service_name],
        }
    }
}
