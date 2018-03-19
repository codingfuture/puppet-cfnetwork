#
# Copyright 2018 (c) Andrey Galkin
#


class cfnetwork::internal::sysctlmods (
    $enable_bridge_filter
) {
    exec {'load_bridge_module':
        command => '/sbin/modprobe bridge',
        unless  => '/sbin/lsmod | /bin/egrep -q "^bridge"',
    }

    if versioncmp($::facts['kernelversion'], '3.18') > 0 {
        exec {'load_br_netfilter_module':
            command => [
                '/sbin/modprobe br_netfilter',
                'while ! sysctl net.bridge.bridge-nf-call-iptables; do sleep 1; done'
            ].join(' && '),
            unless  => '/sbin/lsmod | /bin/egrep -q "^br_netfilter"',
        }
    }

    exec {'load_conntrack_module':
        command => [
            '/sbin/modprobe -a nf_conntrack nf_conntrack_ipv4 nf_conntrack_ipv6',
            'while ! sysctl net.netfilter.nf_conntrack_generic_timeout; do sleep 1; done'
        ].join(' && '),
        unless  => '/sbin/lsmod | /bin/egrep -q "^nf_conntrack"',
    }
}
