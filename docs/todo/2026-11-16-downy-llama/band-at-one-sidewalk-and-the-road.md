**The roadblock's band covers its own sidewalk and the road, 128px, and leaves the far sidewalk
whole, 64px** ("match the roadblocks size to one sidewalk + road", inbox #1465 in spry-plover).

Today the catalogue roadblock (`roadblock` in `src/events/event_catalogue.gd`, standing on a road
or crossing tile) is solid as `GroundShape.band(60.0)`, a segment reaching 60px either way across
the street from the lane it stands in. A lane's centre is 80px from the street's outer edge (or
112px), so the band runs from 20px to 140px: it leaves 20px of its own sidewalk and 52px of the far
one.

What the build keeps true, each checked: the one-sidewalk rule (`OneSidewalkOpenRule`), the route
sidewalk rule (`RouteSidewalkRule`), the escape's walk rules (`WalkOpenRule`, `WalkGround`), the
region wall's three roadblock bodies across a street (M200, a region wall has a guard on each
sidewalk), which a resized band must neither open nor overlap, day 13's roadblock phase and swap
(`DawnRoadblocks`, and the open entry minty-trout, day 13: the roadblock band answers her task), the
guard's post and his notice, and the cars its tiles turn. The drawn barrier matches the band
exactly, since a thing that stands still is solid at the width it is drawn (**events**, **cues**).

Measured and reported: route-street roadblocks a day by heat, the free-line probe
(`tests/probes/m129_zero_cost_line.gd`), and the escape's fingerprints. A test fails with the old
width: the far sidewalk whole at 64px, and the band covering the road.
