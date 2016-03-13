# Change Log

All notable changes to this project will be documented in this file. This
project adheres to [Semantic Versioning](http://semver.org/).

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

[0.9.6]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.9.6
[0.9.5]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.9.5
[0.9.4]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.9.4
[0.9.3]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.9.3
[0.9.2]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.9.2
[0.9.1]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.9.1
[0.9.0]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.9.0