#
# Copyright 2017 (c) Andrey Galkin
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
    case $::cfnetwork::dns {
        '$recurse', '$local': {
            $dns_listen = '127.0.0.1'
            cfnetwork::service_port { 'local:dns': }
        }
        '$serve': {
            $dns_listen = '0.0.0.0'
            cfnetwork::service_port { 'local:dns': }
            cfnetwork::service_port { "${cfnetwork::service_face}:dns": }
        }
        default: {
            $dns_listen = undef
        }
    }

    package { 'pdnsd': ensure => absent }
    $dns_service = $cfnetwork::dns_service_name

    if $dns_listen {
        $dns_user = $dns_service
        $dns_systemd_unit = "/etc/systemd/system/${dns_service}.service"

        # Serve all exported hosts in location
        Cfnetwork::Internal::Exported_host  <<| location == $cfnetwork::location |>>

        Package['pdnsd'] ->
        package { 'dnsmasq-base': } ->
        package { 'dnsmasq':
            ensure => absent,
        } ->
        cfnetwork::client_port { "any:dns:${dns_service}":
            user=> $dns_user
        } ->
        file { '/etc/dnsmasq.conf':
            mode    => '0600',
            owner   => $dns_user,
            content => epp('cfnetwork/dnsmasq.conf', {
                listen        => $dns_listen,
                upstream      => $upstream,
                dnssec        => $dnssec,
                custom_config => $custom_config,
            }),
            notify  => Service[$dns_service],
        } ->
        file { $dns_systemd_unit:
            mode    => '0644',
            content => epp('cfnetwork/dnsmasq.service', {
                after    => '',
                memlimit => $memlimit,
            }),
        } ->
        Exec['cfnetwork-systemd-reload'] ->
        service { $dns_service:
            ensure   => running,
            enable   => true,
            provider => 'systemd',
        } ->
        File['/etc/resolv.conf']
    } else {
        service { $dns_service:
            ensure   => stopped,
            enable   => false,
            provider => 'systemd',
        }
    }
}
