#
# Copyright 2017 (c) Andrey Galkin
#

require 'ipaddr'

Puppet::Functions.create_function(:'cfnetwork::sort_ipv') do
    dispatch :sort_ipv_1 do
        param 'Array[String[1]]', :data
    end

    dispatch :sort_ipv_2 do
        param 'Array[String[1]]', :data
        param 'Array[Variant[String[1], Integer[0]]]', :path
    end
    
    def sort_ipv_1(data)
        v4 = []
        v6 = []

        data.each do |v|
            begin
                addr = IPAddr.new v
            rescue
                raise ArgumentError, "Invalid IP: #{v}"
            end

            
            if addr.ipv4?
                v4 << v
            elsif addr.ipv6?
                v6 << v
            else
                raise ArgumentError, "Invalid IP: #{v}"
            end
        end

        return [v4, v6]
    end
    
    def sort_ipv_2(data, path)
        v4 = []
        v6 = []
        
        data.each do |v|
            addr = call_function('dig', [v] + path)

            begin
                addr = IPAddr.new addr
            rescue
                raise ArgumentError, "Invalid IP: #{v}"
            end

            if addr.ipv4?
                v4 << v
            elsif addr.ipv6?
                v6 << v
            else
                raise ArgumentError, "Invalid IP: #{v}"
            end
        end

        return [v4, v6]
    end
end
