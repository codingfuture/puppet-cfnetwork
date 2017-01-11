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

    if $dns_listen {
        $dns_service = 'dnsmasq'
        $dns_user = $dns_service
        $dns_systemd_unit = "/etc/systemd/system/${dns_service}.service"

        # Serve all exported hosts in location
        Cfnetwork::Internal::Exported_host  <<| location == $::cf_location |>>
            -> Service[$dns_service]

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
                listen   => $dns_listen,
                upstream => $upstream,
                dnssec   => $dnssec,
            }),
            notify  => Service[$dns_service],
        } ->
        file { $dns_systemd_unit:
            mode    => '0644',
            content => epp('cfnetwork/dnsmasq.service', {
                after => ''
            }),
        } ->
        Exec['cfnetwork-systemd-reload'] ->
        service { $dns_service:
            ensure   => running,
            enable   => true,
            provider => 'systemd',
        } ->
        File['/etc/resolv.conf']
    }
}
