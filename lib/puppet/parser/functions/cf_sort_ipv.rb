#
# Copyright 2017 (c) Andrey Galkin
#

require 'ipaddr'


module Puppet::Parser::Functions
    newfunction(:cf_sort_ipv,  :type => :rvalue) do |args|
        v4 = []
        v6 = []
        
        data = args[0]
        raise(ArgumentError, "Data array must be provided") unless data.is_a? Array
        
        if args.size == 2
            Puppet::Parser::Functions.function(:dig)
            
            path = args[1]
            raise(ArgumentError, "Path must be an array") unless path.is_a? Array
            
            data.each do |v|
                addr = function_dig([v, path])
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
        else
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
        end
        
        [v4, v6]
    end
end
