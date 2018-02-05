#
# Copyright 2016-2018 (c) Andrey Galkin
#


# Please see README
class cfnetwork::sysctl::params {
    $enable_bridge_filter = !$::cfnetwork::is_router
    $optimize_10gbe = $::cfnetwork::optimize_10gbe
    $mem_bytes = $::facts['memory']['system']['total_bytes']

    $file_max = $mem_bytes / 1024 / 1024 / 4 * 256 # 256 per 4MB
    $somaxconn = $file_max / 32 # 2048 per 1GB
    $netdev_max_backlog = $optimize_10gbe ? { true => 30000, default => 2000 }
    $tcp_rmem_max = $optimize_10gbe ? { true => 67108864, default => 16777216 }
    $tcp_wmem_max = $optimize_10gbe ? { true => 67108864, default => 16777216 }
    $tcp_rmem_default = $tcp_rmem_max / 128
    $tcp_wmem_default = $tcp_wmem_max / 128
}
