# Change Log

All notable changes to this project will be documented in this file. This
project adheres to [Semantic Versioning](http://semver.org/).

## [0.11.3](https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.11.3)
- NEW: Puppet 5.x support
- NEW: Ubuntu Zesty support

## [0.11.2]
- Fixed 'cfsystem::bind_address' to support undefined 'local' face

## [0.11.1]
- BROKEN

## [0.11.0]
- Andded 'cfnetwork:firewall' anchor
- Added a new 'cfnetwork::bind_address' API to properly retrieve iface bind address
- Deprecated 'cf_get_iface_address'
- Added automatic creation of host entries for each interface and additional addresses
- Added cfnetwork::hosts parameter
- Added cfnetwork:pre-firewall anchor
- Added fetch of exported host entries used in firewall
- Changed to allow failed to resolve DNS entries in firewall config
    not to break bootstrap
- Changed prune of unknown /etc/hosts entries
- Improved cf_location/cf_location_pool support on initial deployment
    when facts are not set (lookup of cfsystem parameters)
- Changed $firewall_provider to 'auto' by default

## [0.10.1]
- Minor improvement for error reporting of internal features
- Allowed to specify expected DHCP address range as firewall hint
- Fixed to allow DNS queries to all destinations if DNS servers are not set
- Changed to use dnsmasq instead of abandoned pdnsd
    NOTE: dnsmasq has no recursive resolver
- Renamed '$recurse' to '$local' to better reflect dnsmasq behavior
- Disabling IPv6 DHCP, if IPv6 = 'auto'

## [0.10.0]
- Much better support for IPv6 now
- Small redesign of cfnetwork::iface parameters
    - `extra_routes` & `extra_addresses` are deprecated now
    - `address` - can list multiple addresses now
    - `gateway` - can list multiple entries (one for IPv4 and one for IPv6)
    - `routes` - any additional routes
- Fixed `routes`/`extra_routes` paramter type for Struct case
- Improved handling of DHCP interfaces
- Fixed to use IPv6 "auto" method, if 'static' is missing IP address

## [0.9.11]
- Implemented support for ipsets
- Automatic newer puppet-lint fixes
- Fixed puppet-lint and metadata-json-lint warnings
- Enforced strict parameter types

## [0.9.10]
- Fixed minor rare issue with new Puppet 4.6.x release

## [0.9.9]
- Added an explicit dependency of resolv.conf on pdnsd

## [0.9.8]
- Updated supported OS list

## [0.9.7]

- Minor fixes for strict mode

## [0.9.6]

- Fixed systems with kernel 3.18+ to load br_netfilter to properly setup sysctl

## [0.9.5]

- Fixed issue of missing default parameters in DB of exported port/host.
   It is a workaround for: [PUP-6014](https://tickets.puppetlabs.com/browse/PUP-6014)
- Fixed pdnsd to serve /etc/hosts entries for all domains
- Fixed to properly refresh pdnsd on new exported host getting added

## [0.9.4]

- Fixed to fully generate resolv.conf overriding all dynamic changes
- Changed sysctl configuration to use PuppetLabs approved augeas module

## [0.9.3]

- Fixed outdated root DNS server list in pdnsd config
- Fixed cfnetwork::iface:extra_routes to support plain string, but not only arrays
- Fixed to enforce current DNS settings in /etc/resolv.conf


## [0.9.2]

- Added hiera.yaml version 4 support
- Fixed to use 'local' instead of 'lo' interface for DNS service

## [0.9.1]

- Fixed error with DHCP interfaces
- Added possibility to provide custom debian interface template
- Changed to export resources by default (requires PuppetDB)

## [0.9.0]

Initial release

[0.11.2]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.11.2
[0.11.1]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.11.1
[0.11.0]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.11.0
[0.10.1]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.10.1
[0.10.0]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.10.0
[0.9.11]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.9.11
[0.9.10]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.9.10
[0.9.9]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.9.9
[0.9.8]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.9.8
[0.9.7]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.9.7
[0.9.6]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.9.6
[0.9.5]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.9.5
[0.9.4]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.9.4
[0.9.3]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.9.3
[0.9.2]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.9.2
[0.9.1]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.9.1
[0.9.0]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.9.0