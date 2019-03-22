#
# Copyright 2017-2019 (c) Andrey Galkin
#

Puppet::Functions.create_function(:'cfnetwork::fw_face') do
    dispatch :fw_face do
        param 'Cfnetwork::Bindface', :iface
    end

    def fw_face(iface)
        iface, addr_num = iface.split(':', 2)
        return iface
    end
end
