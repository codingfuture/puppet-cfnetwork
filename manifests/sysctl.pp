#
# Copyright 2016 (c) Andrey Galkin
#


# Please see README
class cfnetwork::sysctl (
    Boolean $enable_bridge_filter = $cfnetwork::sysctl::params::enable_bridge_filter, # module needs to be loaded
    Integer $rp_filter = 1,
    Integer $netdev_max_backlog =  $cfnetwork::sysctl::params::netdev_max_backlog,
    Integer $tcp_fin_timeout = 3,
    Integer $tcp_keepalive_time = 300,
    Integer $tcp_keepalive_probes = 3,
    Integer $tcp_keepalive_intvl = 15,
    Integer $tcp_max_syn_backlog = 4096,
    Integer $tcp_no_metrics_save = 1,
    Integer $tcp_rfc1337 = 1,
    Integer $tcp_sack = 1,
    Integer $tcp_slow_start_after_idle = 0,
    Integer $tcp_synack_retries = 2,
    Integer $tcp_syncookies = 1,
    Integer $tcp_timestamps = 1,
    Integer $tcp_tw_recycle = 1,
    Integer $tcp_tw_reuse = 1,
    Integer $tcp_window_scaling = 1,
    Integer $file_max = $cfnetwork::sysctl::params::file_max, # 256 per 4MB
    Integer $somaxconn = $cfnetwork::sysctl::params::somaxconn, # 2048 per 1GB
    String[1] $ip_local_port_range = '2000 65535',
    # no need to overkill for UDP and others
    Integer $rmem_max = 212992,
    Integer $wmem_max = 212992,
    Integer $rmem_default = $rmem_max,
    Integer $wmem_default = $wmem_max,
    # TCP
    Integer $tcp_rmem_max = $cfnetwork::sysctl::params::tcp_rmem_max,
    Integer $tcp_wmem_max = $cfnetwork::sysctl::params::tcp_wmem_max,
    Integer $tcp_rmem_default = $cfnetwork::sysctl::params::tcp_rmem_default,
    Integer $tcp_wmem_default = $cfnetwork::sysctl::params::tcp_wmem_default,
    Optional[Integer] $nf_conntrack_max = undef, # kernel does good autoconfig
    Optional[Integer] $nf_conntrack_expect_max = undef, # kernel does good autoconfig
    Integer $nf_conntrack_generic_timeout = 600,
    Integer $nf_conntrack_tcp_timeout_syn_sent = 20,
    Integer $nf_conntrack_tcp_timeout_syn_recv = 10,
    Integer $nf_conntrack_tcp_timeout_established = 1200,
    Integer $nf_conntrack_tcp_timeout_last_ack = 5,
    Integer $nf_conntrack_tcp_timeout_time_wait = 3,
    Integer $nf_conntrack_tcp_loose = 0,
    Integer $nf_conntrack_tcp_be_liberal = 0,
    Integer $nf_conntrack_tcp_max_retrans = 3,
    Integer $nf_conntrack_udp_timeout = 30,
    Integer $nf_conntrack_udp_timeout_stream = 60,
    Integer $nf_conntrack_icmp_timeout = 30,
)  inherits cfnetwork::sysctl::params {
    include stdlib
    assert_private();

    # Spoof protection (reverse-path filter)
    # Turn on Source Address Verification in all interfaces to
    # prevent some spoofing attacks    
    sysctl{ 'net.ipv4.conf.default.rp_filter':
            value => $rp_filter}
    sysctl{ 'net.ipv4.conf.all.rp_filter':
            value => $rp_filter}

    # This disables TCP Window Scaling (http://lkml.org/lkml/2008/2/5/167),
    # and is not recommended.
    sysctl{ 'net.ipv4.tcp_syncookies':
            value => $tcp_syncookies}

    # Use bridge, if you really need this
    sysctl{ 'net.ipv4.conf.default.proxy_arp': value => 0 }
    sysctl{ 'net.ipv4.conf.all.proxy_arp': value => 0 }


    $enable_routing = $cfnetwork::is_router ? { true => 1, default => 0 };
    sysctl{ 'net.ipv4.conf.default.forwarding':
            value => $enable_routing}
    sysctl{ 'net.ipv4.conf.all.forwarding':
            value => $enable_routing}
    sysctl{ 'net.ipv6.conf.default.forwarding':
            value => $enable_routing}
    sysctl{ 'net.ipv6.conf.all.forwarding':
            value => $enable_routing}


    # ICMP security
    #---
    # Ignore ICMP broadcast
    sysctl{ 'net.ipv4.icmp_echo_ignore_broadcasts':
            value => 1}
    # Ignore bogus ICMP errors
    sysctl{ 'net.ipv4.icmp_ignore_bogus_error_responses':
            value => 1}

    # Do not accept ICMP redirects (prevent MITM attacks)
    sysctl{ 'net.ipv4.conf.default.accept_redirects':
            value => 0}
    sysctl{ 'net.ipv4.conf.all.accept_redirects':
            value => 0}
    sysctl{ 'net.ipv6.conf.default.accept_redirects':
            value => 0}
    sysctl{ 'net.ipv6.conf.all.accept_redirects':
            value => 0}

    # Do not send ICMP redirects (we are not a router)
    sysctl{ 'net.ipv4.conf.default.send_redirects':
            value => 0}
    sysctl{ 'net.ipv4.conf.all.send_redirects':
            value => 0}

    # Do not accept IP source route packets (we are not a router)
    sysctl{ 'net.ipv4.conf.default.accept_source_route':
            value => 0}
    sysctl{ 'net.ipv4.conf.all.accept_source_route':
            value => 0}

    # IPv6 specific
    sysctl{ 'net.ipv6.conf.default.router_solicitations':
            value => 0}
    sysctl{ 'net.ipv6.conf.default.accept_ra_rtr_pref':
            value => 0}
    sysctl{ 'net.ipv6.conf.default.accept_ra_pinfo':
            value => 0}
    sysctl{ 'net.ipv6.conf.default.accept_ra_defrtr':
            value => 0}
    sysctl{ 'net.ipv6.conf.default.autoconf':
            value => 0}
    sysctl{ 'net.ipv6.conf.default.dad_transmits':
            value => 0}
    sysctl{ 'net.ipv6.conf.default.max_addresses':
            value => 1}

    # Optimize network
    #---

    # yep, socket related
    sysctl{ 'fs.file-max':
            value => $file_max}
    sysctl{ 'net.core.netdev_max_backlog':
            value => $netdev_max_backlog}
    sysctl{ 'net.core.somaxconn':
            value => $somaxconn}
    sysctl{ 'net.core.rmem_max':
            value => $rmem_max}
    sysctl{ 'net.core.wmem_max':
            value => $wmem_max}
    sysctl{ 'net.core.rmem_default':
            value => $rmem_default}
    sysctl{ 'net.core.wmem_default':
            value => $wmem_default}

    # do not choke on not enough ports
    sysctl{ 'net.ipv4.ip_local_port_range':
            value => $ip_local_port_range}

    # Basic TCP tuning
    sysctl{ 'net.ipv4.tcp_tw_recycle':
            value => $tcp_tw_recycle}
    sysctl{ 'net.ipv4.tcp_tw_reuse':
            value => $tcp_tw_reuse}
    sysctl{ 'net.ipv4.tcp_fin_timeout':
            value => $tcp_fin_timeout}
    sysctl{ 'net.ipv4.tcp_slow_start_after_idle':
            value => $tcp_slow_start_after_idle}
    sysctl{ 'net.ipv4.tcp_window_scaling':
            value => $tcp_window_scaling}
    sysctl{ 'net.ipv4.tcp_timestamps':
            value => $tcp_timestamps}
    sysctl{ 'net.ipv4.tcp_sack':
            value => $tcp_sack}
    sysctl{ 'net.ipv4.tcp_no_metrics_save':
            value => $tcp_no_metrics_save}
    sysctl{ 'net.ipv4.tcp_synack_retries':
            value => $tcp_synack_retries}
    sysctl{ 'net.ipv4.tcp_rfc1337':
            value => $tcp_rfc1337}
    sysctl{ 'net.ipv4.tcp_keepalive_time':
            value => $tcp_keepalive_time}
    sysctl{ 'net.ipv4.tcp_keepalive_probes':
            value => $tcp_keepalive_probes}
    sysctl{ 'net.ipv4.tcp_keepalive_intvl':
            value => $tcp_keepalive_intvl}
    sysctl{ 'net.ipv4.tcp_max_syn_backlog':
            value => $tcp_max_syn_backlog}
    sysctl{ 'net.ipv4.tcp_rmem':
            value     => "4096 ${tcp_rmem_default} ${tcp_rmem_max}" }
    sysctl{ 'net.ipv4.tcp_wmem':
            value     => "4096 ${tcp_wmem_default} ${tcp_wmem_max}" }


    # Avoid firewall on bridge traffic - make a router instead,
    # if you really need.
    #
    # To avoid issues on router or xen host, load bridge module
    # even if not really used.
    if !$enable_bridge_filter {
        exec {'load_bridge_module':
            command => '/sbin/modprobe bridge',
            unless  => '/sbin/lsmod | /bin/egrep "^bridge"',
        }
        if versioncmp($::facts['kernelversion'], '3.18') > 0 {
            exec {'load_br_netfilter_module':
                command => '/sbin/modprobe br_netfilter',
                unless  => '/sbin/lsmod | /bin/egrep "^br_netfilter"',
            }
        }
        sysctl{ 'net.bridge.bridge-nf-call-ip6tables':
                value   => 0,
                require => Exec['load_bridge_module'],
        }
        sysctl{ 'net.bridge.bridge-nf-call-iptables':
                value   => 0,
                require => Exec['load_bridge_module']
        }
        sysctl{ 'net.bridge.bridge-nf-call-arptables':
                value   => 0,
                require => Exec['load_bridge_module'] }
    }

    # Netfilter optimization
    #---
    exec {'load_conntrack_module':
        command => '/sbin/modprobe nf_conntrack_ipv4',
        unless  => '/sbin/lsmod | /bin/egrep "^nf_conntrack_ipv4"',
    }

    if $nf_conntrack_max {
        sysctl{ 'net.netfilter.nf_conntrack_max':
            value   => $nf_conntrack_max,
            require => Exec['load_conntrack_module'],
        }
    }
    if $nf_conntrack_expect_max {
        sysctl{ 'net.netfilter.nf_conntrack_expect_max':
            value   => $nf_conntrack_max,
            require => Exec['load_conntrack_module'],
        }
    }

    sysctl{ 'net.netfilter.nf_conntrack_generic_timeout':
            value   => $nf_conntrack_generic_timeout,
            require => Exec['load_conntrack_module'],
    }
    sysctl{ 'net.netfilter.nf_conntrack_tcp_timeout_syn_sent':
            value   => $nf_conntrack_tcp_timeout_syn_sent,
            require => Exec['load_conntrack_module'],
    }
    sysctl{ 'net.netfilter.nf_conntrack_tcp_timeout_syn_recv':
            value   => $nf_conntrack_tcp_timeout_syn_recv,
            require => Exec['load_conntrack_module'],
    }
    sysctl{ 'net.netfilter.nf_conntrack_tcp_timeout_established':
            value   => $nf_conntrack_tcp_timeout_established,
            require => Exec['load_conntrack_module'],
    }
    sysctl{ 'net.netfilter.nf_conntrack_tcp_timeout_fin_wait':
            value   => $tcp_fin_timeout,
            require => Exec['load_conntrack_module'],
    }
    sysctl{ 'net.netfilter.nf_conntrack_tcp_timeout_last_ack':
            value   => $nf_conntrack_tcp_timeout_last_ack,
            require => Exec['load_conntrack_module'],
    }
    sysctl{ 'net.netfilter.nf_conntrack_tcp_timeout_time_wait':
            value   => $nf_conntrack_tcp_timeout_time_wait,
            require => Exec['load_conntrack_module'],
    }
    sysctl{ 'net.netfilter.nf_conntrack_tcp_loose':
            value   => $nf_conntrack_tcp_loose,
            require => Exec['load_conntrack_module'],
    }
    sysctl{ 'net.netfilter.nf_conntrack_tcp_be_liberal':
            value   => $nf_conntrack_tcp_be_liberal,
            require => Exec['load_conntrack_module'],
    }
    sysctl{ 'net.netfilter.nf_conntrack_tcp_max_retrans':
            value   => $nf_conntrack_tcp_max_retrans,
            require => Exec['load_conntrack_module'],
    }
    sysctl{ 'net.netfilter.nf_conntrack_udp_timeout':
            value   => $nf_conntrack_udp_timeout,
            require => Exec['load_conntrack_module'],
    }
    sysctl{ 'net.netfilter.nf_conntrack_udp_timeout_stream':
            value   => $nf_conntrack_udp_timeout_stream,
            require => Exec['load_conntrack_module'],
    }
    sysctl{ 'net.netfilter.nf_conntrack_icmp_timeout':
            value   => $nf_conntrack_icmp_timeout,
            require => Exec['load_conntrack_module'],
    }
}
