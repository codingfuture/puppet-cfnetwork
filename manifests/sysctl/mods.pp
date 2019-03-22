#
# Copyright 2018-2019 (c) Andrey Galkin
#


class cfnetwork::sysctl::mods {
    if versioncmp($::facts['kernelversion'], '3.18') > 0 {
        exec {'load_br_netfilter_module':
            command => [
                '/sbin/modprobe br_netfilter',
                'while ! sysctl net.bridge.bridge-nf-call-iptables; do sleep 1; done'
            ].join(' && '),
            unless  => '/sbin/lsmod | /bin/egrep -q "^br_netfilter"',
        }
    } else {
        exec {'load_bridge_module':
            command => [
                '/sbin/modprobe bridge',
                'while ! sysctl net.bridge.bridge-nf-call-iptables; do sleep 1; done'
            ].join(' && '),
            unless  => '/sbin/lsmod | /bin/egrep -q "^bridge"',
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
