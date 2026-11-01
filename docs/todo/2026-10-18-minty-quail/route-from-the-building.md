# `--route` from the building section

A run booted into the escape's building section with `--route` stops on the building's brief: the route
rig (`src/dev/route_rig.gd`) is built with the city, which the building has not yet made, and it does not
walk the building, so nobody presses the building's brief or wins the building. Once a building is won by
other means, the rig presses the city's first brief and walks on to an exit.

**Build:** `--route` follows a run from the building boot to an exit, hands-free. Whether that means the
rig walks the building, or presses its brief and leaves the win to a person, is the open question; the
building is not walked by the route rig today and nothing in the repo walks it.
