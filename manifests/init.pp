
#
# $main - main iface, see cfnetwork::iface
# $dns - dns server list
# $ifaces - array of see cfnetwork::iface
#
class cfnetwork (
    $main = undef,
    $dns = undef,
    $ifaces = undef,
    $dnat_ports = undef,
    $service_ports = undef,
    $client_ports = undef,
    $router_ports = undef,
    $describe_services = undef,
    $is_router = false,
    $optimize_10gbe = false, # TODO: facter
    $service_face = 'any',
    $firewall_provider = 'cffirehol',
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
        ip => $host_ip,
    }
    @@cfnetwork::internal::exported_host {$::trusted['certname']:
        host_aliases => [ $::trusted['hostname'] ],
        ip => $host_ip,
    }
    
    #---
    cfnetwork::describe_service { 'alltcp':
        server => 'tcp/1:65535'
    }
    cfnetwork::describe_service { 'alludp':
        server => 'udp/1:65535'
    }
    cfnetwork::describe_service { 'allports':
        server => [ 'udp/1:65535', 'tcp/1:65535']
    }
    
    # Pre-defined ports
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
        include $firewall_provider
    }
}
