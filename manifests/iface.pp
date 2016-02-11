
define cfnetwork::iface (
    $device = $title,
    $method = 'static',
    $address = undef,
    $extra_addresses = undef,
    $extra_routes = undef,
    $gateway = undef,

    $dns_servers = undef,
    $domain = undef,

    $bridge_ports = undef,
    $bridge_stp = undef,
    $bridge_fd = undef,
    
    $bond_slaves = undef,
    $bond_primary = undef,
    $bond_mode = undef,
    $bond_miimon = undef,
    
    $preup = undef,
    $up = undef,
    $down = undef,
    $postdown = undef,
    
    $ipv6 = false,
    $force_public = false,
) {
    include stdlib
    
    case $method {
        'static': {}
        'dhcp': {}
        default: { fail("Unknown \$method ${method}") }
    }
    
    if $device == 'lo' {
        fail('Do not define local interface manually')
    }
    
    if $title == 'local' {
        fail('"local" iface name is reserved for lo device')
    }
    
    $addr_split = split($address, '/')
    $ip = $addr_split[0]
    $netmask = $addr_split[1]
    validate_ip_address($ip)
    validate_integer($netmask)

    case $::operatingsystem {
        'Debian', 'Ubuntu': {
            file { "/etc/network/interfaces.d/${title}":
                owner   => root,
                group   => root,
                mode    => '0644',
                replace => true,
                content => epp('cfnetwork/debian_iface.epp', {
                    device          => $device,
                    method          => $method,
                    iface_type      => 'inet',
                    address         => $ip,
                    extra_addresses => $extra_addresses,
                    extra_routes    => $extra_routes,
                    netmask         => $netmask,
                    gateway         => $gateway,
                    dns_servers     => $dns_servers,
                    domain          => $domain,
                    bridge_ports    => $bridge_ports,
                    bridge_stp      => $bridge_stp,
                    bridge_fd       => $bridge_fd,
                    bond_slaves     => $bond_slaves,
                    bond_primary    => $bond_primary,
                    bond_mode       => $bond_mode,
                    bond_miimon     => $bond_miimon,
                    preup           => $preup,
                    up              => $up,
                    down            => $down,
                    postdown        => $postdown,
                    ipv6            => $ipv6,
                }),
            }
        }
        default: { err("Not supported OS ${::operatingsystem}") }
    }
    
    @cfnetwork_firewall_iface { $title:
        ensure          => present,
        device          => $device,
        method          => $method,
        address         => $address,
        extra_addresses => $extra_addresses,
        extra_routes    => $extra_routes,
        gateway         => $gateway,
        force_public    => $force_public,
    }
    
    if $dns_servers {
        cfnetwork::client_port { 'any:dns:cfnetwork':
            dst => $dns_servers
        }
    }
}