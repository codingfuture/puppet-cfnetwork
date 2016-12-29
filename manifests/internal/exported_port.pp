#
# Copyright 2016 (c) Andrey Galkin
#


# Please see README
define cfnetwork::internal::exported_port (
    # $title = "fqdn:port_type:iface:service"
    $hostname, # = $::trusted['certname']
    $location, # = $::cf_location
    $location_pool, # = $::cf_location_pool
    $src = undef,
    $dst = undef,
    $user = undef,
    $group = undef,
    $to_dst = undef,
    $to_port = undef,
    $comment = undef,
) {
}
