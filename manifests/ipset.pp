
# Please see README
define cfnetwork::ipset(
    Variant[String[1], Array[String[1]]]
        $addr,
    Enum['net', 'ip']
        $type = 'net',
    Boolean
        $dynamic = false,
    Optional[String[1]]
        $comment = undef,
) {
    @cfnetwork_firewall_ipset { $title:
        ensure  => present,
        addr    => $addr,
        type    => $type,
        dynamic => $dynamic,
        comment => $comment,
    }
}
