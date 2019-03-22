#
# Copyright 2017-2019 (c) Andrey Galkin
#

Puppet::Functions.create_function(:'cfnetwork::bind_address') do
    dispatch :bind_address do
        param 'Cfnetwork::Bindface', :iface
    end

    def bind_address(iface)
        iface, addr_num = iface.split(':', 2)
        addr_num = 0 if addr_num.nil?
        
        return "127.0.0.#{addr_num + 1}" if iface == 'local'

        if iface_resource = closure_scope.findresource("Cfnetwork::Iface[#{iface}]")
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
        else
            raise(ArgumentError, "Resource not found for #{iface}")
        end
    end
end
