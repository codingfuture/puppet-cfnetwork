#
# Copyright 2016-2017 (c) Andrey Galkin
#


# Please see README
define cfnetwork::internal::exported_port (
    # $title = "fqdn:port_type:iface:service"
    $hostname, # = $::trusted['certname']
    $location, # = $cfnetwork::location
    $location_pool, # = $cfnetwork::location_pool
    $src = undef,
    $dst = undef,
    $user = undef,
    $group = undef,
    $to_dst = undef,
    $to_port = undef,
    $comment = undef,
) {
}
