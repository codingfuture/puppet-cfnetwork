#
# Copyright 2017-2018 (c) Andrey Galkin
#


define cfnetwork::internal::fetch_hosts(
    Optional[Variant[Array[String[1]], String[1]]]
        $src = undef,
    Optional[Variant[Array[String[1]], String[1]]]
        $dst = undef,
    Optional[Variant[Array[String[1]], String[1]]]
        $to_dst = undef,
) {
    assert_private()

    if !$cfnetwork::local_dns {
        flatten(delete_undef_values([$src, $dst, $to_dst])).each |$v| {
            if $v =~ /^(?!ipset:)([a-zA-Z][a-zA-Z0-9_-]+)(\.[a-zA-Z][a-zA-Z0-9_-]+)*$/ and
                !defined(Cfnetwork::Internal::Exported_host[$v])
            {
                if $cfnetwork::hosts_locality == 'pool' {
                    Cfnetwork::Internal::Exported_host  <<|
                        (title == $v) and
                        (location == $cfnetwork::location) and
                        (location_pool == $cfnetwork::location_pool)
                    |>>
                } else {
                    Cfnetwork::Internal::Exported_host  <<|
                        (title == $v) and
                        (location == $cfnetwork::location)
                    |>>
                }
            }
        }
    }
}
