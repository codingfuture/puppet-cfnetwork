#
# Copyright 2017 (c) Andrey Galkin
#


module Puppet::Parser::Functions
    newfunction(:cf_get_iface_address,  :type => :rvalue, :arity => 1) do |args|
        iface = args[0]
        raise(ArgumentError, "Invalid interface") unless iface
        
        iface = findresource(iface.to_s)
        addr = iface['address']
        addr = [addr] unless addr.is_a? Array
        
        eaddr = iface['extra_addresses']
        eaddr = [eaddr] unless eaddr.is_a? Array
        
        ret = (addr + eaddr).map do |v|
            begin
                addr = IPAddr.new v
            rescue
                next
            end

            v.split('/')[0]
        end
        
        ret
    end
end
