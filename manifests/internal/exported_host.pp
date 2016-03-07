define cfnetwork::internal::exported_host (
    # $title = "hostname"
    $host_aliases,
    $ip,
    $location/* = $::cf_location*/,
    $location_pool/* = $::cf_location_pool*/,
) {
    if $title != $::trusted['certname'] {
        host { $title:
            host_aliases => $host_aliases,
            ip           => $ip,
        }
    }
}
