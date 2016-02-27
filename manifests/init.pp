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
    $main = undef,
    $dns = undef,
    $ifaces = undef,
    $describe_services = undef,
    $service_ports = undef,
    $client_ports = undef,
    $dnat_ports = undef,
    $router_ports = undef,
    $is_router = false,
    $optimize_10gbe = false, # TODO: facter
    $service_face = 'any',
    $firewall_provider = 'cffirehol',
    $export_resources = true,
) {
    include cfnetwork::sysctl

    #---
    case $::operatingsystem {
        'Debian', 'Ubuntu': { include cfnetwork::debian }
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
    if $main and
        (($main['method'] == 'static') or ($main['method'] == undef))
    {
        $host_ip = split($main['address'],'/')[0]
    } else {
        $host_ip = $::networking['ip'] # fact
    }
    
    host {$::trusted['certname']:
        host_aliases => [ $::trusted['hostname'] ],
        ip           => $host_ip,
    }
    if $export_resources {
        @@cfnetwork::internal::exported_host {$::trusted['certname']:
            host_aliases => [ $::trusted['hostname'] ],
            ip           => $host_ip,
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
    
    # Predefined ports
    #---
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
