# cfnetwork

## Description

The module exclusively configures system network interfaces, related sysctl items
and system firewall. The module is designed to be used with Hiera-like data providers.


## Concept

Each network interface has a unique name. This identifier is used in firewall port
definition to specify the interface to apply the rule.

There are predefined interface names:
* `'local'` - assign rule to loopback interface
* `'any'` - assign rule to all interfaces, unless src or dst is specified. See below.

Each firewall rule name has format of `"interface:service"`. Optionally, additional tag can be
specified like `"interface:service:tag"`. Such format allows resource to be defined multiple
times with no name clash and no need for explicit virtual resource processing.

**!!! ALL CONNECTIONS ARE BLOCKED BY DEFAULT, EVEN LOCAL !!!**

The module is designed without actual firewall implementation to serve as abstract API
for plug&play firewall rules definition. For example:

* this module automatically enables DNS clients and services, if '$local'
    or '$serve' is configured
* **[cfauth]** module automatically enables incoming SSH connections on configured ports
    from admin hosts
* **[cfsystem]** module automatically defines rules for NTP, APT repositories, APT cache,
    puppet, etc.
* **[cfdb]** module allows outgoing database connections for particular users.


Examples:

```puppet
    class { 'cfnetwork':
      main => {
        device  => 'eth0',
        address => [
            '128.0.0.2/24',
            '128.0.0.3/24',
            '128.0.0.4/24',
        ],
        gateway => '128.0.0.1',
      },
      dns => ['8.8.8.8', '8.8.4.4'],
      is_router => true,
    }
    cfnetwork::iface { 'dmz1':
        device  => 'eth2',
        address => '128.0.1.2/24',
        # no gateway
    }
    cfnetwork::iface { 'dmz2':
        device  => 'eth3',
        address => '128.0.2.2/24',
        # no gateway
    }
    cfnetwork::describe_service { myservice':
        server => ['tcp/123', 'udp/234']
    }
    cfnetwork::describe_service { myhttp':
        server => ['tcp/80', 'tcp/443']
    }
    # allow incoming for myservice on auto-detected dmz1 and dmz2 ifaces
    # note: still, please consider using explicit ifaces
    cfnetwork::service_port { 'any:myservice':
        src => [
            '128.0.1.0/24',
            '128.0.2.0/24',
            'ipset:myclients',
        ]
    }
    # allow client request on main interface
    cfnetwork::client_port { 'main:myhttp:tag1': }
    # duplicate, no worry
    cfnetwork::client_port { 'main:myhttp:tag2': }
    # allow client request on dmz2
    cfnetwork::client_port { 'dmz2:myhttp': }
    # Allow clients from dmz1 to dmz2
    cfnetwork::router_port { 'dmz1/dmz2:myhttp': }
    # DNAT external to dmz2
    cfnetwork::dnat_port { 'main/dmz2:myhttp':
        to_dst => 'dmz2server',
    }
    cfnetwork::ipset { 'myclients':
        addr => [
            '128.0.3.0/24',
        ]
    }
    cfnetwork::ipset { 'otherset':
        addr => [
            '128.0.4.0/24',
            'ipset:myclients',
        ]
    }
```
    
The same using Hiera:

```yaml
    # someconfig.yaml
    classes:
        - cfnetwork
    cfnetwork::main:
        device: eth0
        address:
            - '128.0.0.2/24'
            - '128.0.0.3/24'
            - '128.0.0.4/24'
        gateway: '128.0.0.1'
    cfnetwork::dns:
        - '8.8.8.8'
        - '8.8.4.4'
    cfnetwork::is_router: true
    cfnetwork::ifaces:
        dmz1:
            device: eth1
            address: '128.0.1.1/24'
        dmz2:
            device: eth2
            address: '128.0.2.1/24'
    cfnetwork::describe_services:
        myservice:
            server:
                - 'tcp/123'
                - 'udp/234'
        myhttp: { server: [ 'tcp/80', 'tcp/443' ] }
    cfnetwork::service_ports:
        'any:myservice':
            src:
                - '128.0.1.0/24'
                - '128.0.2.0/24'
                - 'ipset:myclients'
    cfnetwork::client_ports:
        'main:myhttp:tag1': {}
        'main:myhttp:tag2': {}
        'dmz2:myhttp': {}
    cfnetwork::router_ports
        'dmz1/dmz2:myhttp': {}
    cfnetwork::dnat_ports:
        'main/dmz2:myhttp': {}
    cfnetwork::ipsets:
        myclients:
            addr:
                - '128.0.3.0/24'
        otherset:
            addr:
                - '128.0.4.0/24'
                - 'ipset:myclients'
```

### 'any' interface matching rules

If client port has 'src' property set then rule is applied only to matching interfaces.
If server port has 'dst' property set then rule is applied only to matching interfaces.

A matching interface is one of:
* 'address' and 'extra_addresses' of interface subnets matches 'dst'
* otherwise default interface is used, which is 'gateway' property defined

### Public interface notes

* All not routable private networks will be dropped for incoming and outgoing packets
* Automatic SNAT to `address` enabled for all valid destinations with unroutable source address
* Default policy is DROP. For private interfaces default policy is REJECT

### ipset notes

* Main name pattern: `[a-z][a-z0-9_]`
* Referred as "ipset:<main_name' (e.g. `ipset:admins`)
* Allowed in any `src/dst/to_dst` of port types
* Allowed in `addr` of other ipsets
* Additional entries can be defined with partial definition:
    * Partial name pattern: `<main_name>:[a-z][a-z0-9_]`
    * It's not allowed to refer to partial names
    * Note: `type` attribute must match the main definition

### Dependency on configured firewall

Please depend on `Anchor['cfnetwork:firewall']`, if you need new firewal configuration before
some processing.


## Technical Support

* [Example configuration](https://github.com/codingfuture/puppet-test)
* Free & Commercial support: [support@codingfuture.net](mailto:support@codingfuture.net)

## Setup

Please use [librarian-puppet](https://rubygems.org/gems/librarian-puppet/) or
[cfpuppetserver module](https://codingfuture.net/docs/cfpuppetserver) to deal with dependencies.

There is a known r10k issue [RK-3](https://tickets.puppetlabs.com/browse/RK-3) which prevents
automatic dependencies of dependencies installation.

## Examples

Please check [codingufuture/puppet-test](https://github.com/codingfuture/puppet-test) for
example of a complete infrastructure configuration and Vagrant provisioning.

## Implicitly created resources

```yaml
cfnetwork::ipsets:
    blacklist:
        type: net
        dynamic: true
    whitelist:
        type: net
        dynamic: true
    localnet:
        type: net
        addr:
            - 10.0.0.0/8
            - 172.16.0.0/12
            - 192.168.0.0/16
            - 'fd00::/8'
cfnetwork::describe_services:
    'dns':
        server: [ 'tcp/53', 'udp/53' ]
        client: 'any'
    'alltcp':
        server: 'tcp/1:65535'
        client: 'any'
        comment: "Use to open all TCP ports (e.g. for local)"
    'alludp':
        server: 'udp/1:65535'
        client: 'any'
        comment: "Use to open all UDP ports (e.g. for local)"
    'allports':
        server: [ 'udp/1:65535', 'tcp/1:65535']
        client: 'any'
        comment: "Use to open all TCP and UDP ports (e.g. for local)"
cfnetwork::service_ports:
    'local:dns': {}
        comment: 'only in $serve or $local mode'
    "${cfnetwork::service_face}:dns":
        comment: 'only in $serve mode'
cfnetwork::client_ports:
    'any:dns:dnsmasq':
        user: 'dnsmasq'
        comment: 'only in $serve or $local mode'
    'any:dns:cfnetwork':
        dst: $cfnetwork::dns
        comment: 'unless in $serve or $local mode'
    'any:dns:cfnetwork':
        comment: 'only if no DNS servers are configured'
    '{iface}:dhcp:cfnetwork':
        comment: "for IPv4 ifaces with method=dhcp"
    '{iface}:dhcpv6:cfnetwork':
        comment: "for IPv6 ifaces with method=dhcp"
cfnetwork::router_ports:
    # for each cfnetwork::dnat_port
anchor:
    'cfnetwork:firewall'
```


## Classes and resources types


### `cfnetwork` class

* `main`
      Main network interface configuration, see cfnetwork::iface for details.
      Can be defined separately.
* `dns`
      DNS server list. Can be defined directly with one of cfnetwork::iface.
      Special values:
      - '$local' - Setup own DNS cache
      - '$serve' - Same as '$recure', but also serve clients on $service_face
* 'ifaces'
      Create cfnetwork::iface resources, if set
* 'describe_services'
      Create cfnetwork::describe_services resources, if set
* 'service_ports'
      Create cfnetwork::service_port resources, if set
* 'client_ports'
      Create cfnetwork::client_port resources, if set
* 'dnat_ports'
      Create cfnetwork::dnat_port resources, if set
* 'router_ports'
      Create cfnetwork::router_port resources, if set
* 'is_router' = `false`
      If true, enables packet forwarding and other related sysctl
* 'optimize_10gbe' = `false`
      If true, optimizes network stack for 10+ Gbit network
* 'firewall_provider' = `'auto'`
      Module name, implementing fireall provider. Its value is a soft
      dependency. 'cffirehol' is used by default for Linux
* 'export_resources' = `true`
      If true, resources are exported to PuppetDB as well
* `service_face` = `'any'` - the interface to listen for client of configured services
* `hosts = undef` - arbitrary definition of custom /etc/hosts entries based on `host` type

### `cfnetwork::iface` type

* `device` =` $title` - system interface device name, e.g. 'eth0'
* `method` = 'static' - address setup method ('static' of 'dhcp'). Please avoid DHCP as possible.
    Note: it is allowed to specify 'net/prefix' address as firewall hint for private interfaces
* `address` - list of IPv4 and IPv6 addresses with /netprefix
    * (string)
    * (array)
* `routes` - additional routes, if any
    * (string) - maps to `network` in hash below
    * (hash)
        * `network` - network address to route
        * `via` - gateway to use, if any
        * `metric` - metric to set, if any
* `gateway` - default gateway to setup. Only one iface must have one.
    * (string) either IPv4 or IPv6 address
    * (array) one IPv4 and one IPv6 address
* `dns_servers` - DNS servers to use. Only one iface should have one.
* `domain` - DNS search domain, auto-detect by default
* Bridge setup:
    * `bridge_ports` - Indicates a bridge device. List of participating ports.
    * `bridge_stp` - enabled STP, if set
    * `bridge_fd` - forwarding delay
* Bonding setup:
    * `bond_slaves` - slave device list
    * `bond_primary` - primary slave
    * `bond_mode` - bonding mode, see modinfo bonding
    * `bond_miimon` = MII monitoring interval, see modinfo bonding
* `preup` list of arbitrary commands to execute before bringing the interface up (not recommended, prefer `up`)
* `up` list of arbitrary commands to execute after interface is up
* `down` list of arbitrary commands to execute before interface goes down
* `postdown` list of arbitrary commands to execute after interface gets down
* `ipv6 = false` control IPv6 support on the interface
    * `false` - disable IPv6
    * `true` - enable IPv6
    * `'auto'` - enable IPv6, if explicitly configured
    * `'only'` - enable IPv6 and disable IPv4
* `force_public` - firewall-specific. Force mark the interface as public, even if it has address from
    private range, what is useful in cloud environments with suboptimal NAT.
* `debian_template` = `'cfnetwork/debian_iface.epp'` - supply own template for non-standard interface setup
* `custom_args` - provide custom arguments to custom `$debian_template`

### `cfnetwork::ipset` type

Define `ipset` item.

* Title:
    * Main name: `[a-z][a-z0-9_]*` (e.g. "blacklist")
    * Partial additions to the main list: `<main_name>:[a-z][a-z0-9_]*` (e.g. "blacklist:attackers", "blacklist:spam")
* `$addr` - mixes list of IPv4 & IPv6 addresses and other ipsets in form `ipset:<main_name>`
* `$type = 'net'` - either `ip` or `net`. See `man ipset`
* `$dynamic = false` - notify firewall that additional addresses can be added dynamically (e.g. dynamic list of attackers)
* `$comment = undef` - arbitrary comment


### `cfnetwork::describe_service` type

Describe service to use in firewall rules.

* Title: `<service>`
* `server` - list of server-side ports in format "protocol/port", example: 'tcp/80', 'udp/53'
* `client` = 'default' - list of client-side ports, 'default' - firewall-specific (all ports or 1024-65535)

### `cfnetwork::client_port type`

Define allowed outgoing connection for <service> on <iface>.

* Title: `<iface>:<service>[:<tag>]`
* `src` - list of allowed source addresses, if any
* `dst` - list of allowed destination addresses, if any
* `user` - list of allowed system user names
* `group` - list of allowed system group names
* `comment` - arbitrary comment

### `cfnetwork::service_port` type

Define allowed incoming connection for <service> on <iface>.

* Title: `<iface>:<service>[:<tag>]`
* `src` - list of allowed source addresses, if any
* `dst` - list of allowed destination addresses, if any
* `comment` - arbitrary comment


### `cfnetwork::router_port` type

Define allowed routing connection from <inface> to <outface> for <service>.

* Title: `<iface>/<outface>:<service>[:<tag>]`
* `src` - list of allowed source addresses, if any
* `dst` - list of allowed destination addresses, if any
* `comment` - arbitrary comment

### `cfnetwork::dnat_port` type

Destination Network Address Translation <inface> to <outface> for <service>.
Note: implicit cfnetwork::route_port is defined - no need to define one manually.

* Title: `<iface>/<outface>:<service>[:<tag>]`
* `src` - list of allowed source addresses, if any
* `dst` - list of allowed destination addresses, if any
* `to_dst` - DNAT to specific address(s)
* `to_port` - (int) re-assign port, if needed
* `comment` - arbitrary comment

### `cfnetwork::dnsmasq` class

Tune automatically installed `dnsmasq`, if `$local` or `$serve`.

* `$upstream = ['8.8.8.8', '8.8.4.4']` - upstream servers, Public Google DNS by default
* `$dnssec = true` - if true, enable DNSSEC validation on dnsmasq
* `$memlimit = '8M'` - systemd memory limit for dnsmasq service
* `$custom_config = ''` - any arbitrary text to include in dnsmasq.conf

### `cfnetwork::sysctl` class

Self-explanatory sysctl settings with their defaults, unless specially noted:

* `$enable_bridge_filter` = `!$::cfnetwork::is_router`
    Only if false, loads `bridge` module and disable netfilter calls on bridges.
    Use routing instead of bridges, if you really need to do filtering or enable it.
    After enabling, you will need to cleanup sysctl.conf and setup values manually.
* `$rp_filter` = `1`
* `$netdev_max_backlog` = `30000` if `$cfnetwork::optimize_10gbe` else `2000`
* `$tcp_fin_timeout` = `3`
    *Note: it can be too aggressive*
* `$tcp_keepalive_time` = `300`
* `$tcp_keepalive_probes` = `3`
* `$tcp_keepalive_intvl` = `15`
* `$tcp_max_syn_backlog` = `4096`
* `$tcp_no_metrics_save` = `1`
* `$tcp_rfc1337` = `1`
* `$tcp_sack` = `1`
* `$tcp_slow_start_after_idle` = `0`
* `$tcp_synack_retries` = `2`
* `$tcp_syncookies` = `1`
* `$tcp_timestamps` = `1`
* `$tcp_tw_recycle` = `1`
* `$tcp_tw_reuse` = `1`
* `$tcp_window_scaling` = `1`
* `$file_max` = 256 per every 4MB of RAM
* `$somaxconn` = 2048 per every 1GB of RAM
* `$ip_local_port_range` = `'2000 65535'`
* `$rmem_max` = `212992`
    *Note: it does not apply to TCP*
* `$wmem_max` = `212992`
    *Note: it does not apply to TCP*
* `$rmem_default` = `$rmem_max`
* `$wmem_default` = `$wmem_max`
* `$tcp_rmem_max` = `67108864` if `$cfnetwork::optimize_10gbe` else `16777216`
* `$tcp_wmem_max` = `67108864` if `$cfnetwork::optimize_10gbe` else `16777216`
* `$tcp_rmem_default` = `$tcp_rmem_max / 128`
    *Please note, you have to setup manually, if `$tcp_rmem_max` is set*
* `$tcp_wmem_default` = `$tcp_wmem_max / 128`
    *Please note, you have to setup manually, if `$tcp_wmem_max` is set*
* `$nf_conntrack_max` = `undef`
    *Note: recent kernels do good autoconfig*
* `$nf_conntrack_expect_max` = `undef`
    *Note: recent kernels do good autoconfig*
* `$nf_conntrack_generic_timeout` = `600`
* `$nf_conntrack_tcp_timeout_syn_sent` = `20`
    *Note: it can be too aggressive*
* `$nf_conntrack_tcp_timeout_syn_recv` = `10`
    *Note: it can be too aggressive*
* `$nf_conntrack_tcp_timeout_established` = `1200`
    *Note: it can be too aggressive*
* `$nf_conntrack_tcp_timeout_last_ack` = `5`
    *Note: it can be too aggressive*
* `$nf_conntrack_tcp_timeout_time_wait` = `3`
    *Note: it can be too aggressive*
* `$nf_conntrack_tcp_loose` = `0`
    *Note: you don't want to set 1 with pedantic firewall*
* `$nf_conntrack_tcp_be_liberal` = `0`
    *Note: you don't want to set 1 with pedantic firewall*
* `$nf_conntrack_tcp_max_retrans` = `3`
    *Note: it can be too aggressive*
* `$nf_conntrack_udp_timeout` = `30`
    *Note: it can be too aggressive*
* `$nf_conntrack_udp_timeout_stream` = `60`
    *Note: it can be too aggressive*
* `$nf_conntrack_icmp_timeout` = `30`

### Public API

* `Cfnetwork::Bindaddress` - type alias for bind address name
* `Cfnetwork::Ifacename` - type alias for interface name
* `Cfnetwork::Port` - type alias for network port Integer
* `cfnetwork::bind_address(arg)` - get bind address for specified arg, where:
    * 'iface' - first address of Cfnetwork::Iface[iface] resource
    * 'iface:N' - address #N of Cfnetwork::Iface[iface] resource
* `cfnetwork::fw_face(arg)` - extract firewall interface name
    from Cfnetwork::Bindaddress

[cfauth]: https://codingfuture.net/docs/cfauth
[cfsystem]: https://codingfuture.net/docs/cfsystem
