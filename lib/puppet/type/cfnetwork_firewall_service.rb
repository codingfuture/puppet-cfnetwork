#
# Copyright 2016 (c) Andrey Galkin
#

Puppet::Type.newtype(:cfnetwork_firewall_service) do
    desc "DO NOT USE DIRECTLY. Notify firewall of available service definitions."
    
    ensurable do
        defaultvalues
        defaultto :absent
    end
    
    newparam(:name) do
        desc "Service name"
        isnamevar
    end

    newproperty(:server_ports, :array_matching => :all) do
        desc "Define server ports"
        isrequired
        
        newvalue(/^([a-z0-9]+)\/([1-9][0-9]{0,4})(:[1-9][0-9]{0,4})?$/)
    end

    newproperty(:client_ports, :array_matching => :all) do
        desc "Define client ports"
        
        newvalues('default', 'any', /^([a-z0-9]+)\/([1-9][0-9]{0,4})(:[1-9][0-9]{0,4})?$/)
        defaultto(:default)
    end

    newproperty(:comment) do
        desc "Arbitrary single-line comment"
    end
end
