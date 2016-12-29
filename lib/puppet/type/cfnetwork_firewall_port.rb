#
# Copyright 2016 (c) Andrey Galkin
#

require 'ipaddr'
require "resolv"

Puppet::Type.newtype(:cfnetwork_firewall_port) do
    desc "DO NOT USE DIRECTLY. Defines a firewall port."
    
    ensurable do
        defaultvalues
        defaultto :absent
    end
    
    autorequire(:user) do
        self[:user] if self[:user]
    end
    
    newparam(:name) do
        desc "
Client/Service ports: '{port_type}:{iface}:{service}'
DNAT/Router ports: '{port_type}:{inface}/{outface}:{service}'
"
        isnamevar
    end
    
    {
        :src => 'Source address to match against, if set',
        :dst => 'Destination address to match against, if set'
    }.each do |p, d|
        newproperty(p, :array_matching => :all) do
            desc d
            
            validate do |value|
                ips = value.split(':', 2)
                
                if ips[0] == 'ipset'
                    unless ips[1] =~ /^[a-z][a-z0-9_]*$/
                        raise ArgumentError, "%s is not valid ipset name" % value
                    end
                    return true
                end
                
                value = munge value
                ip = IPAddr.new(value) # may raise ArgumentError

                unless ip.ipv4? or ip.ipv6?
                    raise ArgumentError, "%s is not a valid IPv4 or IPv6 address" % value
                end
            end
            
            munge do |value|
                return value if value.split(':', 2)[0] == 'ipset'
                
                begin
                    ip = IPAddr.new(value)
                    return value
                rescue
                    return Resolv.getaddress value
                end
            end
        end
    end

    newproperty(:user, :array_matching => :all) do
        desc "User name to check for outgoing connections, if set"
        
        validate do |value|
            unless value =~ /^[a-zA-Z_][a-zA-Z0-9_-]*$/
                raise ArgumentError, "%s is not valid username" % value
            end
        end
    end

    newproperty(:group, :array_matching => :all) do
        desc "Group name to check for outgoing connections, if set"
        
        validate do |value|
            unless value =~ /^[a-zA-Z_][a-zA-Z0-9_-]*$/
                raise ArgumentError, "%s is not valid groupname" % value
            end
        end
    end
    
    newproperty(:to_dst) do
        desc "Destination address for DNAT, if dnat type of port.
NOTE: use proper load balancer instead of iptables for multiple endpoints
or use firewall $custom_headers for advanced configuration
"
        
        validate do |value|
            value = munge value
            ip = IPAddr.new(value) # may raise ArgumentError

            unless ip.ipv4? or ip.ipv6?
                raise ArgumentError, "%s is not a valid IPv4 or IPv6 address" % value
            end
        end
        
        munge do |value|
            begin
                ip = IPAddr.new(value)
                return value
            rescue
                return Resolv.getaddress value
            end
        end
    end
    
    newproperty(:to_port) do
        desc "Destination port for DNAT, if dnat type of port"
        
        validate do |value|
            unless value.is_a? Integer and value > 0 and value < 0xFFFF
                raise ArgumentError, "%s is not a valid port" % value
            end
        end
    end
    
    newproperty(:comment) do
        desc "Arbitrary single-line comment"
    end
end
