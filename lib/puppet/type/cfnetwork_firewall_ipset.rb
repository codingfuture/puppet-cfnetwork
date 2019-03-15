#
# Copyright 2016-2018 (c) Andrey Galkin
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
                value = munge value
            end
            
            munge do |value|
                ips = value.split(':', 2)
                
                if ips[0] == 'ipset'
                    unless ips[1] =~ /^[a-z][a-z0-9_]*$/
                        raise ArgumentError, "%s is not valid ipset name" % value
                    end
                    return value
                end
                
                begin
                    ip = IPAddr.new(value)
                    return value
                rescue
                    unless value =~ /^([a-zA-Z0-9_-]+)(\.[a-zA-Z0-9_-]+)*$/
                        raise ArgumentError, "%s is not valid DNS entry or IP4/6 address" % value
                    end
                    
                    begin
                        return Resolv.getaddress value
                    rescue
                        begin
                            # re-read /etc/hosts
                            return Resolv.new.getaddress value
                        rescue
                            # leave DNS as-is
                            return value
                        end
                    end
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
