#
# Copyright 2017 (c) Andrey Galkin
#


module Puppet::Parser::Functions
    newfunction(:cf_get_bind_address,  :type => :rvalue, :arity => 1) do |args|
        iface = args[0]
        raise(ArgumentError, "Invalid interface #{iface}. Valid: 'iface', 'iface:N', 'host'") unless iface and iface.is_a? String
        
        iface, addr_num = iface.split(':', 2)
        addr_num = 0 if addr_num.nil?
        
        if iface_resource = findresource("Cfnetwork::Iface[#{iface}]")
            addr = iface_resource['address']
            addr = [] if addr.nil?
            addr = [addr] unless addr.is_a? Array
            
            eaddr = iface_resource['extra_addresses']
            eaddr = [] if addr.nil?
            eaddr = [eaddr] unless eaddr.is_a? Array
            
            ret = (addr + eaddr).map do |v|
                begin
                    addr = IPAddr.new v
                rescue
                    next
                end

                v.split('/', 2)[0]
            end

            ret[addr_num]
        #elsif host_resource = findresource("Host[#{iface}]")
        #    host_resource['ip']
        #elsif host_resource = findresource("Host[#{iface}.#{}]")
        #    host_resource['ip']
        else
            raise(ArgumentError, "Resource not found for #{iface}")
        end
    end
end
