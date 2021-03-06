#
# Copyright 2016-2019 (c) Andrey Galkin
#

class cfnetwork (
    Optional[Hash]
        $main = undef,
    Optional[Variant[String[1], Array[String[1]]]]
        $dns = undef,
    Optional[Hash[Cfnetwork::Ifacename, Hash]]
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
    Cfnetwork::Ifacename
        $service_face = 'any',
    String[1]
        $firewall_provider = 'auto',
    Boolean
        $export_resources = true,
    Optional[Hash[String[1], Hash]]
        $hosts = undef,
    Array[String[1]]
        $localnet = [
            '10.0.0.0/8',
            '172.16.0.0/12',
            '192.168.0.0/16',
            'fd00::/8',
        ],
    Enum['location', 'pool']
        $hosts_locality = 'location',
    Boolean
        $prefer_ipv4 = true,
    Enum['on', 'allow-downgrade', 'off']
        $dnssec = 'on',
) {
    include cfnetwork::sysctl
    #---
    $location = pick_default(
        lookup({
            name          => 'cfsystem::hierapool::location',
            default_value => undef,
        }),
        $::facts['cf_location'],
        ''
    )
    $location_pool = pick_default(
        lookup({
            name          => 'cfsystem::hierapool::pool',
            default_value => undef,
        }),
        $::facts['cf_location_pool'],
        ''
    )


    #---
    case $::operatingsystem {
        'Debian', 'Ubuntu': {
            $dns_service_name = 'dnsmasq'
            $def_firewall_provider = 'cffirehol'
            include cfnetwork::debian
        }
        default: { err("Not supported OS ${::operatingsystem}") }
    }

    #---
    case $dns {
        '$local', '$recurse', '$serve': {
            $dns_servers = '127.0.0.1'
            $iface_dns_servers = $dns_servers
            $local_dns = true
        }
        default: {
            if $dns {
                $dns_servers = $dns
            } else {
                $dns_servers = '127.0.0.53'
            }

            $iface_dns_servers = $dns
            $local_dns = false
        }
    }

    # Ensure to clear out all artifacts
    file { '/etc/systemd/network':
        ensure  => directory,
        mode    => '0755',
        purge   => true,
        recurse => true,
        notify  => Exec['cfnetwork-systemd-reload'],
    }
    file { '/etc/systemd/resolved.conf':
        mode    => '0644',
        content => epp('cfnetwork/resolved.conf.epp', {
            dns_servers => $dns_servers,
            dnssec      => $dnssec,
        }),
    }

    if $dns_servers and $local_dns {
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
        # systemd-resolved
        cfnetwork::service_port { 'local:dns:cfnetwork': }
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
                        dns_servers => $iface_dns_servers,
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
            cfnetwork::bind_address('main'),
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
    $ipv4_precedence = $prefer_ipv4 ? {
        true  => 100,
        false => 10,
    }

    file_line { 'Prefer IPv4/IPv6':
        ensure                                => present,
        path                                  => '/etc/gai.conf',
        line                                  => "precedence ::ffff:0:0/96  ${ipv4_precedence}",
        replace                               => true,
        match                                 => 'precedence\s+::ffff:0:0/96',
        match_for_absence                     => true,
        multiple                              => true,
        replace_all_matches_not_matching_line => true,
    }

    #---
    cfnetwork::describe_service { 'dns':
        server => [ 'tcp/53', 'udp/53' ],
        client => 'any',
    }
    cfnetwork::describe_service { 'http':
        server => [ 'tcp/80' ],
        client => 'any',
    }
    cfnetwork::describe_service { 'https':
        server => [ 'tcp/443' ],
        client => 'any',
    }
    cfnetwork::describe_service { 'cfhttp':
        server => [ 'tcp/80', 'tcp/443' ],
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
    cfnetwork::ipset { 'localnet':
        type => 'net',
        addr => $localnet,
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

    #---
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

    # it should be the last
    #--
    if $firewall_provider == 'auto' {
        # dynamic bi-directional dep
        include $def_firewall_provider
    } else {
        # dynamic bi-directional dep
        include $firewall_provider
    }
}
