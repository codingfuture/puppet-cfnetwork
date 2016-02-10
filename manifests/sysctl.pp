
class cfnetwork::sysctl (
    $enable_bridge_filter = false, # module needs to be loaded
    $rp_filter = 1,
    $netdev_max_backlog =  $cfnetwork::sysctl::params::netdev_max_backlog,
    $tcp_fin_timeout = 3,
    $tcp_keepalive_time = 300,
    $tcp_keepalive_probes = 3,
    $tcp_keepalive_intvl = 15,
    $tcp_max_syn_backlog = 4096,
    $tcp_no_metrics_save = 1,
    $tcp_rfc1337 = 1,
    $tcp_sack = 1,
    $tcp_slow_start_after_idle = 0,
    $tcp_synack_retries = 2,
    $tcp_syncookies = 1,
    $tcp_timestamps = 1,
    $tcp_tw_recycle = 1,
    $tcp_tw_reuse = 1,
    $tcp_window_scaling = 1,
    $file_max = $cfnetwork::sysctl::params::file_max, # 256 per 4MB
    $somaxconn = $cfnetwork::sysctl::params::somaxconn, # 2048 per 1GB
    $ip_local_port_range = '2000 65535',
    # no need to overkill for UDP and others
    $rmem_max = 212992,
    $wmem_max = 212992,
    $rmem_default = $rmem_max,
    $wmem_default = $wmem_max,
    # TCP
    $tcp_rmem_max = $cfnetwork::sysctl::params::tcp_rmem_max,
    $tcp_wmem_max = $cfnetwork::sysctl::params::tcp_wmem_max,
    $tcp_rmem_default = $cfnetwork::sysctl::params::tcp_rmem_default,
    $tcp_wmem_default = $cfnetwork::sysctl::params::tcp_wmem_default,
    $nf_conntrack_max = undef, # kernel does good autoconfig
    $nf_conntrack_expect_max = undef, # kernel does good autoconfig
    $nf_conntrack_generic_timeout = 600,
    $nf_conntrack_tcp_timeout_syn_sent = 20,
    $nf_conntrack_tcp_timeout_syn_recv = 10,
    $nf_conntrack_tcp_timeout_established = 1200,
    $nf_conntrack_tcp_timeout_last_ack = 5,
    $nf_conntrack_tcp_timeout_time_wait = 3,
    $nf_conntrack_tcp_loose = 0,
    $nf_conntrack_tcp_be_liberal = 0,
    $nf_conntrack_tcp_max_retrans = 3,
    $nf_conntrack_udp_timeout = 30,
    $nf_conntrack_udp_timeout_stream = 60,
    $nf_conntrack_icmp_timeout = 30,
)  inherits cfnetwork::sysctl::params {
    include stdlib
    assert_private();
    
    # Spoof protection (reverse-path filter)
    # Turn on Source Address Verification in all interfaces to
    # prevent some spoofing attacks    
    sysctl{ 'net.ipv4.conf.default.rp_filter':
            value => $rp_filter, permanent=>true }
    sysctl{ 'net.ipv4.conf.all.rp_filter':
            value => $rp_filter, permanent=>true }
    
    # This disables TCP Window Scaling (http://lkml.org/lkml/2008/2/5/167),
    # and is not recommended.
    sysctl{ 'net.ipv4.tcp_syncookies':
            value => $tcp_syncookies, permanent=>true }

    # Use bridge, if you really need this
    sysctl{ 'net.ipv4.conf.default.proxy_arp': value => 0 }
    sysctl{ 'net.ipv4.conf.all.proxy_arp': value => 0 }

    
    $enable_routing = $cfnetwork::is_router ? { true => 1, default => 0 };
    sysctl{ 'net.ipv4.conf.default.forwarding':
            value => $enable_routing, permanent=>true }
    sysctl{ 'net.ipv4.conf.all.forwarding':
            value => $enable_routing, permanent=>true }
    sysctl{ 'net.ipv6.conf.default.forwarding':
            value => $enable_routing, permanent=>true }
    sysctl{ 'net.ipv6.conf.all.forwarding':
            value => $enable_routing, permanent=>true }
    
    
    # ICMP security
    #---
    # Ignore ICMP broadcast
    sysctl{ 'net.ipv4.icmp_echo_ignore_broadcasts':
            value => 1, permanent=>true }
    # Ignore bogus ICMP errors
    sysctl{ 'net.ipv4.icmp_ignore_bogus_error_responses':
            value => 1, permanent=>true }
    
    # Do not accept ICMP redirects (prevent MITM attacks)
    sysctl{ 'net.ipv4.conf.default.accept_redirects':
            value => 0, permanent=>true }
    sysctl{ 'net.ipv4.conf.all.accept_redirects':
            value => 0, permanent=>true }
    sysctl{ 'net.ipv6.conf.default.accept_redirects':
            value => 0, permanent=>true }
    sysctl{ 'net.ipv6.conf.all.accept_redirects':
            value => 0, permanent=>true }

    # Do not send ICMP redirects (we are not a router)
    sysctl{ 'net.ipv4.conf.default.send_redirects':
            value => 0, permanent=>true }
    sysctl{ 'net.ipv4.conf.all.send_redirects':
            value => 0, permanent=>true }

    # Do not accept IP source route packets (we are not a router)
    sysctl{ 'net.ipv4.conf.default.accept_source_route':
            value => 0, permanent=>true }
    sysctl{ 'net.ipv4.conf.all.accept_source_route':
            value => 0, permanent=>true }
    
    # IPv6 specific
    sysctl{ 'net.ipv6.conf.default.router_solicitations':
            value => 0, permanent=>true }
    sysctl{ 'net.ipv6.conf.default.accept_ra_rtr_pref':
            value => 0, permanent=>true }
    sysctl{ 'net.ipv6.conf.default.accept_ra_pinfo':
            value => 0, permanent=>true }
    sysctl{ 'net.ipv6.conf.default.accept_ra_defrtr':
            value => 0, permanent=>true }
    sysctl{ 'net.ipv6.conf.default.autoconf':
            value => 0, permanent=>true }
    sysctl{ 'net.ipv6.conf.default.dad_transmits':
            value => 0, permanent=>true }
    sysctl{ 'net.ipv6.conf.default.max_addresses':
            value => 1, permanent=>true }

    # Optimize network
    #---
    
    # yep, socket related
    sysctl{ 'fs.file-max':
            value => $file_max, permanent=>true }
    sysctl{ 'net.core.netdev_max_backlog':
            value => $netdev_max_backlog, permanent=>true }
    sysctl{ 'net.core.somaxconn':
            value => $somaxconn, permanent=>true }
    sysctl{ 'net.core.rmem_max':
            value => $rmem_max, permanent=>true }
    sysctl{ 'net.core.wmem_max':
            value => $wmem_max, permanent=>true }
    sysctl{ 'net.core.rmem_default':
            value => $rmem_default, permanent=>true }
    sysctl{ 'net.core.wmem_default':
            value => $wmem_default, permanent=>true }
    
    # do not choke on not enough ports
    sysctl{ 'net.ipv4.ip_local_port_range':
            value => $ip_local_port_range, permanent=>true }
    
    # Basic TCP tuning
    sysctl{ 'net.ipv4.tcp_tw_recycle':
            value => $tcp_tw_recycle, permanent=>true }
    sysctl{ 'net.ipv4.tcp_tw_reuse':
            value => $tcp_tw_reuse, permanent=>true }
    sysctl{ 'net.ipv4.tcp_fin_timeout':
            value => $tcp_fin_timeout, permanent=>true }
    sysctl{ 'net.ipv4.tcp_slow_start_after_idle':
            value => $tcp_slow_start_after_idle, permanent=>true }
    sysctl{ 'net.ipv4.tcp_window_scaling':
            value => $tcp_window_scaling, permanent=>true }
    sysctl{ 'net.ipv4.tcp_timestamps':
            value => $tcp_timestamps, permanent=>true }
    sysctl{ 'net.ipv4.tcp_sack':
            value => $tcp_sack, permanent=>true }
    sysctl{ 'net.ipv4.tcp_no_metrics_save':
            value => $tcp_no_metrics_save, permanent=>true }
    sysctl{ 'net.ipv4.tcp_synack_retries':
            value => $tcp_synack_retries, permanent=>true }
    sysctl{ 'net.ipv4.tcp_rfc1337':
            value => $tcp_rfc1337, permanent=>true }
    sysctl{ 'net.ipv4.tcp_keepalive_time':
            value => $tcp_keepalive_time, permanent=>true }
    sysctl{ 'net.ipv4.tcp_keepalive_probes':
            value => $tcp_keepalive_probes, permanent=>true }
    sysctl{ 'net.ipv4.tcp_keepalive_intvl':
            value => $tcp_keepalive_intvl, permanent=>true }
    sysctl{ 'net.ipv4.tcp_max_syn_backlog':
            value => $tcp_max_syn_backlog, permanent=>true }
    sysctl{ 'net.ipv4.tcp_rmem':
            value => "4096 ${tcp_rmem_default} ${tcp_rmem_max}",
            permanent=>true }
    sysctl{ 'net.ipv4.tcp_wmem':
            value => "4096 ${tcp_wmem_default} ${tcp_wmem_max}",
            permanent=>true }

    
    # Avoid firewall on bridge traffic - make a router instead,
    # if you really need.
    #
    # To avoid issues on router or xen host, load bridge module
    # even if not really used.
    if $enable_bridge_filter or $cfnetwork::is_router {
        exec {'load_bridge_module':
            command => '/sbin/modprobe bridge',
            unless => '/sbin/lsmod | /bin/egrep "^bridge"',
        }
        sysctl{ 'net.bridge.bridge-nf-call-ip6tables':
                value => 0, permanent=>true,
                require => Exec['load_bridge_module'],
        }
        sysctl{ 'net.bridge.bridge-nf-call-iptables':
                value => 0, permanent=>true,
                require => Exec['load_bridge_module']
        }
        sysctl{ 'net.bridge.bridge-nf-call-arptables':
                value => 0, permanent=>true,
                require => Exec['load_bridge_module'] }
    }
    
    # Netfilter optimization
    #---
    exec {'load_conntrack_module':
        command => '/sbin/modprobe nf_conntrack_ipv4',
        unless => '/sbin/lsmod | /bin/egrep "^nf_conntrack_ipv4"',
    }
    
    if $nf_conntrack_max {
        sysctl{ 'net.netfilter.nf_conntrack_max':
            value => $nf_conntrack_max, permanent=>true,
            require => Exec['load_conntrack_module'],
        }
    }
    if $nf_conntrack_expect_max {
        sysctl{ 'net.netfilter.nf_conntrack_expect_max':
            value => $nf_conntrack_max, permanent=>true,
            require => Exec['load_conntrack_module'],
        }
    }
    
    sysctl{ 'net.netfilter.nf_conntrack_generic_timeout':
            value => $nf_conntrack_generic_timeout, permanent=>true,
            require => Exec['load_conntrack_module'],
    }
    sysctl{ 'net.netfilter.nf_conntrack_tcp_timeout_syn_sent':
            value => $nf_conntrack_tcp_timeout_syn_sent, permanent=>true,
            require => Exec['load_conntrack_module'],
    }
    sysctl{ 'net.netfilter.nf_conntrack_tcp_timeout_syn_recv':
            value => $nf_conntrack_tcp_timeout_syn_recv, permanent=>true,
            require => Exec['load_conntrack_module'],
    }
    sysctl{ 'net.netfilter.nf_conntrack_tcp_timeout_established':
            value => $nf_conntrack_tcp_timeout_established, permanent=>true,
            require => Exec['load_conntrack_module'],
    }
    sysctl{ 'net.netfilter.nf_conntrack_tcp_timeout_fin_wait':
            value => $tcp_fin_timeout, permanent=>true,
            require => Exec['load_conntrack_module'],
    }
    sysctl{ 'net.netfilter.nf_conntrack_tcp_timeout_last_ack':
            value => $nf_conntrack_tcp_timeout_last_ack, permanent=>true,
            require => Exec['load_conntrack_module'],
    }
    sysctl{ 'net.netfilter.nf_conntrack_tcp_timeout_time_wait':
            value => $nf_conntrack_tcp_timeout_time_wait, permanent=>true,
            require => Exec['load_conntrack_module'],
    }
    sysctl{ 'net.netfilter.nf_conntrack_tcp_loose':
            value => $nf_conntrack_tcp_loose, permanent=>true,
            require => Exec['load_conntrack_module'],
    }
    sysctl{ 'net.netfilter.nf_conntrack_tcp_be_liberal':
            value => $nf_conntrack_tcp_be_liberal, permanent=>true,
            require => Exec['load_conntrack_module'],
    }
    sysctl{ 'net.netfilter.nf_conntrack_tcp_max_retrans':
            value => $nf_conntrack_tcp_max_retrans, permanent=>true,
            require => Exec['load_conntrack_module'],
    }
    sysctl{ 'net.netfilter.nf_conntrack_udp_timeout':
            value => $nf_conntrack_udp_timeout, permanent=>true,
            require => Exec['load_conntrack_module'],
    }
    sysctl{ 'net.netfilter.nf_conntrack_udp_timeout_stream':
            value => $nf_conntrack_udp_timeout_stream, permanent=>true,
            require => Exec['load_conntrack_module'],
    }
    sysctl{ 'net.netfilter.nf_conntrack_icmp_timeout':
            value => $nf_conntrack_icmp_timeout, permanent=>true,
            require => Exec['load_conntrack_module'],
    }
}
