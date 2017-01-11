#
# Copyright 2016-2017 (c) Andrey Galkin
#


# Please see README
class cfnetwork::debian {
    include stdlib
    assert_private();

    #---
    ensure_packages([
        'ifenslave',
        'resolvconf',
    ])

    #---
    file { '/etc/network/interfaces':
        owner   => root,
        group   => root,
        mode    => '0644',
        content => file('cfnetwork/interfaces'),
    }

    file { '/etc/network/interfaces.d':
        ensure  => directory,
        owner   => root,
        group   => root,
        mode    => '0755',
        purge   => true,
        recurse => true,
    }

    include cfnetwork::dnsmasq
}
