#
# Copyright 2016-2019 (c) Andrey Galkin
#


# Please see README
define cfnetwork::iface (
    String[1]
        $device = $title,
    Enum['static', 'dhcp']
        $method = 'static',

    Variant[String[1], Array[String[1]]]
        $address = [],
    Optional[Variant[String[1], Array[String[1], 0, 2]]]
        $gateway = undef,
    Variant[
        String[1],
        Array[String[1]],
        Array[Struct[{
            network => Optional[String[1]],
            via => Optional[String[1]],
            metric => Integer[0],
        }]]
    ]
        $routes = [],

    Variant[String[1], Array[String[1]]]
        $extra_addresses = [], # deprecated
    Variant[
        String[1],
        Array[String[1]],
        Array[Struct[{
            network => Optional[String[1]],
            via => Optional[String[1]],
            metric => Integer[0],
        }]]
    ]
        $extra_routes = [], # deprecated

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

    Variant[Boolean, Enum['auto', 'only']]
        $ipv6 = 'auto',
    Boolean
        $force_public = false,

    String[1]
        $debian_template = 'cfnetwork/debian_iface.epp',
    Data
        $custom_args = undef,
) {
    include stdlib

    $is_dhcp = ($method == 'dhcp')

    if $device == 'lo' {
        fail('Do not define local interface manually')
    }

    if $title == 'local' {
        fail('"local" iface name is reserved for lo device')
    }

    # mix for auto-detection
    #---
    $all_addresses = any2array($address) + any2array($extra_addresses)
    $all_routes = (any2array($routes) + any2array($extra_routes)).map |$r| {
            if $r =~ Hash {
                $ret = $r
            } elsif $r =~ String[1] {
                $ret = { network => $r }
            } else {
                fail("Invalid route: ${r}")
            }

            $ret
        }

    # Sort by type
    #---

    # puppet-lint warnings
    #[$address4, $address6] = cfnetwork::sort_ipv($all_addresses)
    #[$routes4, $routes6] = cfnetwork::sort_ipv($all_routes)

    $address46 = cfnetwork::sort_ipv($is_dhcp ? {
        true    => [],
        default => $all_addresses
    })
    $address4 = $address46[0]
    $address6 = $address46[1]

    $routes46 = cfnetwork::sort_ipv($all_routes, ['network'])
    $routes4 = $routes46[0]
    $routes6 = $routes46[1]

    $gateway46 = cfnetwork::sort_ipv(any2array(pick($gateway, [])))
    $gateway4 = $gateway46[0][0]
    $gateway6 = $gateway46[1][0]

    if size($gateway46[0]) > 1 {
        fail("Only one default IPv4 gateway is allowed for ${title} iface")
    }
    if size($gateway46[1]) > 1 {
        fail("Only one default IPv6 gateway is allowed for ${title} iface")
    }

    # Get main address & prefix
    #---
    if $address4[0] {
        $addr4_split = split($address4[0], '/')
        $ip4 = $addr4_split[0]
        $netmask4 = $addr4_split[1]
        validate_ip_address($ip4)
        validate_integer($netmask4)
    } else {
        $ip4 = undef
        $netmask4 = undef
    }

    if $address6[0] {
        $addr6_split = split($address6[0], '/')
        $ip6 = $addr6_split[0]
        $netmask6 = $addr6_split[1]
        validate_ip_address($ip6)
        validate_integer($netmask6)
    } else {
        $ip6 = undef
        $netmask6 = undef
    }

    # Detect IPv6/IPv4
    case $ipv6 {
        'auto': {
            if $method == 'static' {
                $ipv6_only = (size($address4) == 0)
                $fact_ipv6 = (size($address6) > 0)
                $fact_ipv4 = false
            } else {
                $ipv6_only = false
                $fact_ipv6 = true
                $fact_ipv4 = true
            }
        }
        'only': {
            $ipv6_only = true
            $fact_ipv6 = true
            $fact_ipv4 = false
        }
        default: {
            $ipv6_only = false
            $fact_ipv6 = $ipv6
            $fact_ipv4 = true
        }
    }

    # link-local routes
    #---
    $link_local_address = ($fact_ipv6 ? {
        true => ['FE80::/10'],
        default => []
    }) + ($fact_ipv4 ? {
        true => ['169.254.0.0/16'],
        default => []
    })

    # Config OS
    #---
    case $::operatingsystem {
        'Debian', 'Ubuntu': {
            $q_bridge_stp = $bridge_stp ? {
                true => 'on',
                default => 'off',
            }
            $unique_args = {
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
                ipv6            => $fact_ipv6,
                custom_args     => $custom_args,
            }

            $unique_args_ipv6 = $ipv6_only ? {
                true    => $unique_args,
                default => {}
            }

            $method_ipv6 = $is_dhcp ? {
                true    => ($ipv6 == 'auto') ? {
                    true    => 'auto',
                    default => $method
                },
                default => (!$ip6) ? {
                    true    => 'auto',
                    default => $method
                }
            }

            $iface_content = [
                $ipv6_only ? {
                    false => epp($debian_template, $unique_args + {
                        device          => $device,
                        method          => $method,
                        iface_type      => 'inet',
                        address         => $ip4,
                        netmask         => $netmask4,
                        gateway         => $gateway4,
                        extra_addresses => $address4[1, -1],
                        extra_routes    => $routes4,
                    }),
                    default => ''
                },
                $fact_ipv6 ? {
                    true => epp($debian_template, $unique_args_ipv6 + {
                        device          => $device,
                        method          => $method_ipv6,
                        iface_type      => 'inet6',
                        address         => $ip6,
                        netmask         => $netmask6,
                        gateway         => $gateway6,
                        extra_addresses => $address6[1, -1],
                        extra_routes    => $routes6,
                        ipv6            => $fact_ipv6,
                    }),
                    default => ''
                }
            ].join("\n")

            file { "/etc/network/interfaces.d/${title}":
                owner   => root,
                group   => root,
                mode    => '0644',
                replace => true,
                content => $iface_content,
            }
        }
        default: { err("Not supported OS ${::operatingsystem}") }
    }

    @cfnetwork_firewall_iface { $title:
        ensure          => present,
        device          => $device,
        method          => $method,
        address         => $all_addresses[0],
        extra_addresses => $all_addresses[1, -1] + $link_local_address,
        extra_routes    => $all_routes,
        gateway         => $gateway,
        force_public    => $force_public,
    }

    #---
    if $is_dhcp {
        if $fact_ipv4 {
            cfnetwork::client_port { "${title}:dhcp:cfnetwork":
                src => '0.0.0.0/0'
            }
        }
        if $fact_ipv6 {
            cfnetwork::client_port { "${title}:dhcpv6:cfnetwork":
                src => '::/0'
            }
        }
    }

    #---
    $all_addresses.each |$index, $host_ip_mask| {
        $host_ip = $host_ip_mask.split('/')[0]

        if $index == 0 {
            $host_prefix = $title
        } else {
            $host_prefix = "${title}${index}"
        }

        host { "${host_prefix}.${::trusted['certname']}":
            host_aliases => [ "${host_prefix}.${::trusted['hostname']}" ],
            ip           => $host_ip,
            before       => Anchor['cfnetwork:pre-firewall']
        }

        if $cfnetwork::export_resources {
            @@cfnetwork::internal::exported_host { "${host_prefix}.${::trusted['certname']}":
                host_aliases  => [ "${host_prefix}.${::trusted['hostname']}" ],
                ip            => $host_ip,
                location      => $cfnetwork::location,
                location_pool => $cfnetwork::location_pool,
            }
        }
    }
}
