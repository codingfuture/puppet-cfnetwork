#
# Copyright 2016-2017 (c) Andrey Galkin
#

require 'ipaddr'
require "resolv"

Puppet::Type.newtype(:cfnetwork_firewall_ipset) do
    desc "DO NOT USE DIRECTLY. Defines a firewall ipset."
    
    ensurable do
        defaultvalues
        defaultto :absent
    end
    
    newparam(:name) do
        desc ""
        isnamevar
        
        validate do |value|
            unless value =~ /^[a-z][a-z0-9_]*(:[a-z][a-z0-9_]*)?$/
                raise ArgumentError, "%s is not valid ipset name" % value
            end
        end
    end
    
    newproperty(:addr, :array_matching => :all) do
        desc 'Member address list'
        
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
    
    newproperty(:type) do
        desc "Address type"
        newvalues(:net, :ip)
        isrequired
    end
    
    newproperty(:dynamic, :boolean => true, :parent => Puppet::Property::Boolean) do
        desc "Added ipset even to that rules where it has no sense with current address list"
        defaultto(false)
    end
    
    newproperty(:comment) do
        desc "Arbitrary single-line comment"
    end
end
