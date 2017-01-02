#
# Copyright 2016-2017 (c) Andrey Galkin
#

require 'ipaddr'
require 'puppet/property/boolean'

Puppet::Type.newtype(:cfnetwork_firewall_iface) do
    desc "DO NOT USE DIRECTLY. Notify firewall of available interface."
    
    ensurable do
        defaultvalues
        defaultto :absent
    end
    
    newparam(:name) do
        desc "Iface name"
        isnamevar
    end
    
    newproperty(:device) do
        desc "Device"
        newvalues(/.*/)
        isrequired
    end

    newproperty(:method) do
        desc "Address setup method"
        newvalues(:static, :dhcp)
        isrequired
    end

    newproperty(:address) do
        desc "Primary IP address"
        
        validate do |value|
            ip = IPAddr.new(value) # may raise ArgumentError

            unless ip.ipv4? or ip.ipv6?
                raise ArgumentError, "%s is not a valid IPv4 or IPv6 address" % value
            end
        end
    end
    
    newproperty(:extra_addresses, :array_matching => :all) do
        desc "Secondary IP addresses"
        
        validate do |value|
            ip = IPAddr.new(value) # may raise ArgumentError

            unless ip.ipv4? or ip.ipv6?
                raise ArgumentError, "%s is not a valid IPv4 or IPv6 address" % value
            end
        end
    end
    
    newproperty(:extra_routes, :array_matching => :all) do
        desc "Extra routes via iface"
        
        validate do |value|
            value = munge value
            
            #---
            unless value.has_key? 'network'
                raise ArgumentError, "route 'network' is missing" % value
            end

            addr = value['network']            
            begin
                ip = IPAddr.new(addr) # may raise ArgumentError

                unless ip.ipv4? or ip.ipv6?
                    raise ArgumentError, "%s is not a valid IPv4 or IPv6 network address" % addr
                end
            rescue
                raise ArgumentError, "%s is not a valid IPv4 or IPv6 network address" % addr
            end

            
            if value.has_key? 'via'
                gw = value['via']
                begin
                    ip = IPAddr.new(gw) # may raise ArgumentError

                    unless ip.ipv4? or ip.ipv6?
                        raise ArgumentError, "%s is not a valid IPv4 or IPv6 address" % gw
                    end
                rescue
                    raise ArgumentError, "%s is not a valid IPv4 or IPv6 gateway address" % addr
                end
            end
            
            if value.has_key? 'metric' and not value['metric'].is_a? Integer
                raise ArgumentError, "'metric' is not integer"
            end
        end
        
        munge do |value|
            unless value.is_a? Hash
                value = { 'network' => value }
            end
            
            value
        end
    end
    
    newproperty(:gateway) do
        desc "Default gateway IP address"
        
        validate do |value|
            ip = IPAddr.new(value) # may raise ArgumentError

            unless ip.ipv4? or ip.ipv6?
                raise ArgumentError, "%s is not a valid IPv4 or IPv6 address" % value
            end
        end
    end
    
    newproperty(:force_public, :boolean => true, :parent => Puppet::Property::Boolean) do
        desc "Ignore auto detect and force iface as public"
        defaultto(false)
    end
end
