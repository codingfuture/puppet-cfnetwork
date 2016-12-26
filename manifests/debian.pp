
# Please see README
class cfnetwork::debian {
    include stdlib
    assert_private();

    #---
    package { 'ifenslave': }
    package { 'resolvconf': }

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

    #---
    case $::cfnetwork::dns {
        '$recurse': {
            $pdns_listen = 'lo'
            cfnetwork::service_port { 'local:dns': }
        }
        '$serve': {
            $pdns_listen = '0.0.0.0'
            cfnetwork::service_port { 'local:dns': }
            cfnetwork::service_port { "${cfnetwork::service_face}:dns": }
        }
        default: {
            $pdns_listen = undef
        }
    }

    if $pdns_listen {
        # Serve all exported hosts in location
        Cfnetwork::Internal::Exported_host  <<| location == $::cf_location |>>
            -> Service['pdnsd']

        cfnetwork::client_port { 'main:dns:pdnsd': user=> 'pdnsd' }
        package { 'pdnsd': }
        service { 'pdnsd': ensure => running }

        file { '/etc/default/pdnsd':
            content => epp('cfnetwork/pdnsd_default.epp'),
            notify  => Service['pdnsd'],
        }

        file { '/etc/pdnsd.conf':
            content => epp('cfnetwork/pdnsd.conf.epp', {
                pdns_listen => $pdns_listen,
            }),
            notify  => Service['pdnsd'],
        }

        Service['pdnsd'] -> File['/etc/resolv.conf']
    } else {
        package { 'pdnsd': ensure => absent }
    }
}
