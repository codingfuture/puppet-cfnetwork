#
# Copyright 2016-2017 (c) Andrey Galkin
#

class cfnetwork (
    Optional[Hash]
        $main = undef,
    Optional[Variant[String[1], Array[String[1]]]]
        $dns = undef,
    Optional[Hash[String[1], Hash]]
        $ifaces = undef,
    Optional[Hash[String[1], Hash]]
        $describe_services = undef,
    Optional[Hash[String[1], Hash]]
        $service_ports = undef,
    Optional[Hash[String[1], Hash]]
        $client_ports = undef,
    Optional[Hash[String[1], Hash]]
        $dnat_ports = undef,
    Optional[Hash[String[1], Hash]]
        $router_ports = undef,
    Optional[Hash[String[1], Hash]]
        $ipsets = undef,
    Boolean
        $is_router = false,
    Boolean
        $optimize_10gbe = false, # TODO: facter
    String[1]
        $service_face = 'any',
    String[1]
        $firewall_provider = 'cffirehol',
    Boolean
        $export_resources = true,
    Optional[Hash[String[1], Hash]]
        $hosts = undef,
) {
    include cfnetwork::sysctl
    #---
    $location = pick(
        $::facts['cf_location'],
        lookup('cfsystem::hierapool::location'),
        ''
    )
    $location_pool = pick(
        $::facts['cf_location_pool'],
        lookup('cfsystem::hierapool::pool'),
        ''
    )


    #---
    case $::operatingsystem {
        'Debian', 'Ubuntu': {
            $dns_service_name = 'dnsmasq'
            include cfnetwork::debian
        }
        default: { err("Not supported OS ${::operatingsystem}") }
    }

    #---
    case $dns {
        '$local', '$recurse', '$serve': {
            $dns_servers = '127.0.0.1'
            $local_dns = true
        }
        default: {
            $dns_servers = $dns
            $local_dns = false
        }
    }

    if $dns_servers {
        file { '/etc/resolv.conf':
            mode    => '0644',
            content => epp('cfnetwork/resolv.conf.epp', {
                dns_servers => $dns_servers,
            }),
        }
        cfnetwork::client_port { 'any:dns:cfnetwork':
            dst => $dns_servers
        }
    } else {
        cfnetwork::client_port { 'any:dns:cfnetwork': }
    }

    # Main iface
    #---
    if $main {
        create_resources(
            cfnetwork::iface,
            {
                main => merge(
                    $main,
                    {
                        dns_servers => $dns_servers,
                        domain => $::trusted['domain'],
                    }
                )
            }
        )
    }

    # additional ifaces
    #---
    if $ifaces {
        create_resources(
            cfnetwork::iface,
            $ifaces
        )
    }

    #---
    if defined(Cfnetwork::Iface['main']) {
        $host_ip = pick_default(
            cf_get_bind_address('main'),
            $::networking['ip']
        )
    } else {
        $host_ip = $::networking['ip'] # fact
    }

    #---
    resources { 'host':
        purge => true,
    }
    host { 'localhost4':
        host_aliases => [
            'localhost',
            'localhost.localdomain',
            'localhost4.localdomain4'
        ],
        ip           => '127.0.0.1',
    }
    host { 'localhost6':
        host_aliases => [
            'localhost',
            'localhost.localdomain',
            'localhost6.localdomain6'
        ],
        ip           => '::1',
    }

    host {$::trusted['certname']:
        host_aliases => [ $::trusted['hostname'] ],
        ip           => $host_ip,
        before       => Anchor['cfnetwork:pre-firewall']
    }

    if $export_resources {
        @@cfnetwork::internal::exported_host {$::trusted['certname']:
            host_aliases  => [ $::trusted['hostname'] ],
            ip            => $host_ip,
            location      => $cfnetwork::location,
            location_pool => $cfnetwork::location_pool,
        }
    }

    #---
    cfnetwork::describe_service { 'dns':
        server => [ 'tcp/53', 'udp/53' ],
        client => 'any',
    }
    cfnetwork::describe_service { 'alltcp':
        server  => 'tcp/1:65535',
        client  => 'any',
        comment => 'Use to open all TCP ports (e.g. for local)',
    }
    cfnetwork::describe_service { 'alludp':
        server  => 'udp/1:65535',
        client  => 'any',
        comment => 'Use to open all UDP ports (e.g. for local)',
    }
    cfnetwork::describe_service { 'allports':
        server  => [ 'udp/1:65535', 'tcp/1:65535'],
        client  => 'any',
        comment => 'Use to open all TCP and UDP ports (e.g. for local)',
    }

    # Statically configured resources
    #---
    cfnetwork::ipset { 'whitelist':
        type    => 'net',
        addr    => [],
        dynamic => true,
    }
    cfnetwork::ipset { 'blacklist':
        type    => 'net',
        addr    => [],
        dynamic => true,
    }

    if $ipsets {
        create_resources(
            cfnetwork::ipset,
            $ipsets
        )
    }

    if $dnat_ports {
        create_resources(
            cfnetwork::dnat_port,
            $dnat_ports
        )
    }

    if $service_ports {
        create_resources(
            cfnetwork::service_port,
            $service_ports
        )
    }

    if $client_ports {
        create_resources(
            cfnetwork::client_port,
            $client_ports
        )
    }

    if $router_ports {
        create_resources(
            cfnetwork::router_port,
            $router_ports
        )
    }

    if $describe_services {
        create_resources(
            cfnetwork::describe_service,
            $describe_services
        )
    }

    if $firewall_provider {
        # dynamic bi-directional dep
        include $firewall_provider
    }

    if $hosts {
        create_resources('host', $hosts, {
            before => Anchor['cfnetwork:pre-firewall']
        })
    }

    #---
    exec { 'cfnetwork-systemd-reload':
        command     => '/bin/systemctl daemon-reload',
        refreshonly => true,
    }

    #---
    anchor { 'cfnetwork:pre-firewall': }
    anchor { 'cfnetwork:firewall': }
}
