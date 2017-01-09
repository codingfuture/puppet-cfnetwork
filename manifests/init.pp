#
# Copyright 2016-2017 (c) Andrey Galkin
#

#
# Class: cfnetwork
# ===========================
#
# This class configures network interfaces and provides resource-based API to
# configure firewall. Firewall provider must be included in a separate package.
# At the momemnt, the only official provider is cffirehol. This functionality
# also optimizes standard network sysctl parameters.
#
# Parameters
# ----------
#
# * `main`
#       Main network interface configuration, see cfnetwork::iface for details.
#       Can be defined separately.
#
# * `dns`
#       DNS server list. Can be defined directly with one of cfnetwork::iface.
#       Special values:
#       - '$recurse' - Setup own recourse DNS cache
#       - '$serve' - Same as '$recure', but also serve clients on $service_face
#
# * 'ifaces'
#       Create cfnetwork::iface resources, if set
#
# * 'describe_services'
#       Create cfnetwork::describe_services resources, if set
#
# * 'service_ports'
#       Create cfnetwork::service_port resources, if set
#
# * 'client_ports'
#       Create cfnetwork::client_port resources, if set
#
# * 'dnat_ports'
#       Create cfnetwork::dnat_port resources, if set
#
# * 'router_ports'
#       Create cfnetwork::router_port resources, if set
#
# * 'is_router'
#       If true, enables packet forwarding and other related sysctl
#
# * 'optimize_10gbe'
#       If true, optimizes network stack for 10+ Gbit network
#
# * 'firewall_provider'
#       Module name, implementing fireall provider. Its value is a soft
#       dependency. 'cffirehol' is used by default
#
# * 'export_resources'
#       If true, resources are exported to PuppetDB as well
#
# Examples
# --------
#
# @example
#    class { 'cfnetwork':
#      main => {
#        device  => 'eth0',
#        address => '128.0.0.2/24',
#        gateway => '128.0.0.1',
#      },
#      dns => ['128.0.1.1', '128.0.1.2'],
#    }
#
# Authors
# -------
#
# Andrey Galkin <andrey@futoin.org>
#
# Copyright
# ---------
#
# Copyright 2016 Andrey Galkin
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
) {
    include cfnetwork::sysctl

    #---
    case $::operatingsystem {
        'Debian', 'Ubuntu': {
            include cfnetwork::debian
            $dns_service_name = 'pdnsd'
        }
        default: { err("Not supported OS ${::operatingsystem}") }
    }

    #---
    case $dns {
        '$recurse', '$serve': { $dns_servers = '127.0.0.1' }
        default: { $dns_servers = $dns }
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
            cf_get_iface_address(Cfnetwork::Iface['main'])[0],
            $::networking['ip']
        )
    } else {
        $host_ip = $::networking['ip'] # fact
    }

    host {$::trusted['certname']:
        host_aliases => [ $::trusted['hostname'] ],
        ip           => $host_ip,
    }
    if $export_resources {
        @@cfnetwork::internal::exported_host {$::trusted['certname']:
            host_aliases  => [ $::trusted['hostname'] ],
            ip            => $host_ip,
            location      => $::cf_location,
            location_pool => $::cf_location_pool,

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
}
