# Change Log

All notable changes to this project will be documented in this file. This
project adheres to [Semantic Versioning](http://semver.org/).

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

[0.9.3]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.9.3
[0.9.2]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.9.2
[0.9.1]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.9.1
[0.9.0]: https://github.com/codingfuture/puppet-cfnetwork/releases/tag/v0.9.0