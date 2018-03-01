#
# Copyright 2017-2018 (c) Andrey Galkin
#

# Please see README
class cfnetwork::dnsmasq(
    Array[String[1]]
        $upstream = [
            '8.8.8.8',
            '8.8.4.4',
        ],
    Boolean
        $dnssec = true,
    String[1]
        $memlimit = '8M',
    String
        $custom_config = '',
) {
    assert_private();

    #---
    $dnssec_actual = $::facts['operatingsystem'] ? {
        'Debian' => (versioncmp($::facts['operatingsystemrelease'], '9') >= 0) ? {
            true    => $dnssec,
            default => false
        },
        'Ubuntu' => (versioncmp($::facts['operatingsystemrelease'], '16.04') >= 0) ? {
            true    => $dnssec,
            default => false
        },
        default  => $dnssec
    }

    #---
    case $::cfnetwork::dns {
        '$recurse', '$local': {
            $dns_listen = '127.0.0.1'
            cfnetwork::service_port { 'local:dns': }
        }
        '$serve': {
            $dns_listen = '0.0.0.0'
            cfnetwork::service_port { 'local:dns': }
            cfnetwork::service_port { "${cfnetwork::service_face}:dns":
                src => 'ipset:localnet',
            }
        }
        default: {
            $dns_listen = undef
        }
    }

    #---
    if $dns_listen and $dnssec_actual != $dnssec {
        $dnssec_message = [
            'Forcibly disabled DNSSEC due to bug in dnsmasq < 2.73:',
            'https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=805596'
        ].join("\n")

        notify { 'cfnetwork:dnsmasq:dnssec':
            message  => $dnssec_message,
            loglevel => warning,
        }
    }

    package { 'pdnsd': ensure => absent }
    $dns_service = $cfnetwork::dns_service_name

    if $dns_listen {
        $dns_user = $dns_service
        $dns_systemd_unit = "/etc/systemd/system/${dns_service}.service"

        # Serve all exported hosts in location
        Cfnetwork::Internal::Exported_host  <<| location == $cfnetwork::location |>>

        Package['pdnsd']
        -> package { 'dnsmasq-base': }
        -> package { 'dnsmasq':
            ensure => absent,
        }
        -> cfnetwork::client_port { "any:dns:${dns_service}":
            user=> $dns_user
        }
        -> file { '/etc/dnsmasq.conf':
            mode    => '0600',
            owner   => $dns_user,
            content => epp('cfnetwork/dnsmasq.conf', {
                listen        => $dns_listen,
                upstream      => $upstream,
                dnssec        => $dnssec_actual,
                custom_config => $custom_config,
            }),
            notify  => Service[$dns_service],
        }
        -> file { $dns_systemd_unit:
            mode    => '0644',
            content => epp('cfnetwork/dnsmasq.service', {
                after    => '',
                memlimit => $memlimit,
            }),
        }
        -> Exec['cfnetwork-systemd-reload']
        -> service { $dns_service:
            ensure   => running,
            enable   => true,
            provider => 'systemd',
        }
        -> File['/etc/resolv.conf']
    } else {
        service { $dns_service:
            ensure   => stopped,
            enable   => false,
            provider => 'systemd',
        }
    }
}
