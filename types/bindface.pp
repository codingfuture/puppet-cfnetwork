#
# Copyright 2017-2019 (c) Andrey Galkin
#


type Cfnetwork::Bindface = Variant[
    Cfnetwork::Ifacename,
    Pattern[/^[a-z][a-z0-9]+:[0-9]+$/]
]
