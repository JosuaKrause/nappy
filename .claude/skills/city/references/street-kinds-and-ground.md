# Street kinds and what the ground does to the meter

Read this before changing how many main roads or precincts a city has, how the main road is found,
or any of `City`'s `EXCITEMENT_DECAY_*_MULTIPLIER` constants. The list of every place that reads the
street hierarchy is in `SKILL.md`, "The street hierarchy".

## One main road, two precincts

**The trap is scale. There is one main road and there are two precincts, and that is the design
rather than a parameter.** One of each per *axis* is three kinds of street and no hierarchy among
them: a spine that crosses itself is two spines, and a precinct you meet on every third street is
what a street is. **If a kind starts appearing in every third corridor, it has stopped being a
place.**

**Which corridor is the main road is a fact about a city, so read it off the map.** Computing it as
`index == arterial_index(blocks)` per axis makes a phantom arterial on the other axis, weighted like
the real one but with no lights, no dark asphalt and no clearway.

## The ground is a rate, not a category

Calm 2.0, precinct 1.5, ordinary street 1.0, alley 0.58, main road 0.02, multiplying the excitement
decay — so choosing a route is choosing a **recovery rate** and not only a set of things to walk
past. It is what makes a precinct worth walking to although it is loud, what keeps an alley a
shortcut rather than a rest, and most of what *"a main road is crossed, not walked"* means
arithmetically.

**The multipliers are ratios and the absolute rates are the design.** Move the walking decay and
every one of them is re-derived to hold its own ground's rate (the list of rates is the
docstring above `City.EXCITEMENT_DECAY_CALM_ZONE_MULTIPLIER` in `src/city/city.gd`). `tests/probes/m117_decay.gd` walks each
ground and prints what it actually does, which is how the rates are set rather than guessed.
