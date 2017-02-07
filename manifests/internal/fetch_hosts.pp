#
# Copyright 2017 (c) Andrey Galkin
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
            if $v =~ /^(?!ipset:)([a-zA-Z][a-zA-Z0-9]+)(\.[a-zA-Z][a-zA-Z0-9]+)*$/ and
                !defined(Cfnetwork::Internal::Exported_host[$v])
            {
                Cfnetwork::Internal::Exported_host  <<|
                    (title == $v) and (location == $cfnetwork::location)
                |>>
            }
        }
    }
}
