# Shared components instead of copies that drift

**The crowd's lane movement stays off the map's one `Navigator`** in the refactor: it is a
lane-following held step, a different motion model from the navigator's swept step, so moving it
cannot stay at test parity. Whether it moves later is sunny-osprey, the crowd's lanes on the map's
one navigator, which waits on this entry's remeasuring (inbox #1155 in gray-dolphin).

**Build:** `src/world/navigator.gd`'s header says it is "The one way anything that walks or drives
across a world moves"; it names the crowd's lane step as the exception, so the header is true.
