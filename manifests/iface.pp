#
# Copyright 2016 (c) Andrey Galkin
#


# Please see README
define cfnetwork::iface (
    String[1]
        $device = $title,
    Enum['static', 'dhcp']
        $method = 'static',
    Optional[String[1]]
        $address = undef,
    Optional[Variant[String[1], Array[String[1]]]]
        $extra_addresses = undef,
    Optional[Variant[String[1], Array[String[1]]]]
        $extra_routes = undef,
    Optional[String[1]]
        $gateway = undef,

    Optional[Variant[String[1], Array[String[1]]]]
        $dns_servers = undef,
    Optional[String[1]]
        $domain = undef,

    Optional[Variant[String[1], Array[String[1]]]]
        $bridge_ports = undef,
    Boolean
        $bridge_stp = false,
    Integer[0]
        $bridge_fd = 0,

    Optional[Variant[String[1], Array[String[1]]]]
        $bond_slaves = undef,
    Optional[String[1]]
        $bond_primary = undef,
    Optional[Variant[
        Enum['balance-rr', 'active-backup', 'balance-xor', 'broadcast',
                '802.3ad', 'balance-tlb', 'balance-alb'],
        Integer[0, 6]]]
        $bond_mode = undef,
    Optional[Integer[0]]
        $bond_miimon = undef,

    Optional[Variant[String[1], Array[String[1]]]]
        $preup = undef,
    Optional[Variant[String[1], Array[String[1]]]]
        $up = undef,
    Optional[Variant[String[1], Array[String[1]]]]
        $down = undef,
    Optional[Variant[String[1], Array[String[1]]]]
        $postdown = undef,

    Boolean
        $ipv6 = false,
    Boolean
        $force_public = false,

    String[1]
        $debian_template = 'cfnetwork/debian_iface.epp',
    Data
        $custom_args = undef,
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

    if $address {
        $addr_split = split($address, '/')
        $ip = $addr_split[0]
        $netmask = $addr_split[1]
        validate_ip_address($ip)
        validate_integer($netmask)
    } else {
        $ip = undef
        $netmask = undef
    }

    case $::operatingsystem {
        'Debian', 'Ubuntu': {
            $q_bridge_stp = $bridge_stp ? {
                true => 'on',
                default => 'off',
            }

            file { "/etc/network/interfaces.d/${title}":
                owner   => root,
                group   => root,
                mode    => '0644',
                replace => true,
                content => epp($debian_template, {
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
                    bridge_stp      => $q_bridge_stp,
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
                    custom_args     => $custom_args,
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
