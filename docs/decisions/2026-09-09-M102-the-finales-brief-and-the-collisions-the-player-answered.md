## M102 — The finale's brief and the collisions the player answered · 2026-09-09

Kept here since M102 has no open items left in `TODO.md`; the records of what was built are the
M102 entries above and below.

**The brief, in the player's words:**

> "for the good ending. after completing all tasks. after the last day ends the next scene is the
> hallway in front of the apartment at night with the player holding the sleeping baby (sleep bar
> is full) the goal is to escape. masked men are trying to capture the player, army trucks are
> driving on the streets, explosions happen off screen (but loud enough to cause excitement)
> leaving craters on the street. burnt cars, blockades, craters, etc. block paths through the city.
> but before reaching the city we need to get out of the house. elevator is non-functioning so we
> need to take the staircase down a few floors (not excessively many). the main entrance of the
> building is barricaded so we need to go to the basement walk through the basement corridors to
> the service entrance. we can keep the events inside the house relatively minimal. maybe some
> mice. some masked pursuers that run up the stairs that can be avoided by going into a corridor
> and letting them pass. there might be a fire on one staircase forcing us to use the other
> staircase (all buildings have two egresses). maybe some steam in the basement etc. once back on
> the street grid (emerging from the service exit on the side of the main building). no regular
> cars or regular people on the street. there is a single path through the city that crosses three
> parks (the player can use them to calm down or get the baby back to sleep if it wakes up) ending
> at the tunnel or bridge (or maybe one path for each and the player can choose). this is the
> climax of the story with lots of lethal and dangerous events. help messages show "escape the
> apartment" and "exit the city" in the appropriate places (only in the beginning of each section
> like normal tutorial hints). the timer shows milli second precision for dramatic effect (instead
> of the regular second precision of the main game)"

**Four things the brief collided with in the finale as `docs/NARRATIVE.md` writes it today, each
asked and each answered by the player on 2026-09-09:**

1. **The sabotage stays, and the escape is what it causes.** *("yes, the sabotage is the cause of
   the brutal crackdown.")* Today the good ending is `RESISTANCE_GOAL` reached *and* the day-14
   step "The last night" touched (`ResistanceSteps._finale`, a civic-district contact that sets
   `sabotage_done`), and what it changes is mechanical quiet: every loudspeaker mast is
   silenced (`EventManager.silence_all_masts()`). **Neither the walk home after it nor the escape is easy**
   ([PLAYTEST-121](../playtests/PLAYTEST-121.md): "the escape shouldn't be easy!"): M183, the power
   station and the blackout, takes the traffic lights with the power, so the roads are harder
   that night on purpose. The hallway scene follows the same night, and the trucks and the
   masked men are the regime's answer to what she did. *"No triumphalism"* still governs what is shown
   after the tunnel.
2. **Losing the finale restarts the section, at no Nerve cost.** *("sounds good at that point you
   earned it.")* A day lost costs one Nerve and the day is over; the finale has no next day, and
   the run is already won on paper. Capture, the meter reaching 100, or the clock running out each
   put her back at the start of the section she was in — the hallway, or the service exit — with
   Nerves untouched. A fourteen-day run is never thrown by one wrong turn in the last minutes.
3. **The clock is a day's clock with milliseconds on it, and zero loses.** *("the timer for the
   sequence is the same length and running out loses (the bridge/tunnel collapses or something
   like that). the only change is that in addition to minutes and seconds the timer also shows
   milliseconds. this makes the timer appear faster than just the seconds alone which adds
   additional tension.")* *Asked for one clock counting down through both sections · overturned
   by the player on 2026-09-20 to "180s per section"
   ([PLAYTEST-113](../playtests/PLAYTEST-113.md)), because each section is its own day and a shared
   clock could leave the city's checkpoint unwinnable.* So: each section's clock is
   `DAY_LENGTH_SECONDS` (180s) long like any day; at zero the way out is gone — the bridge or
   the tunnel collapses, or something of that shape — and the section restarts as in 2. The only
   change to the clock itself is the format, `%d:%02d.%03d` in place of `%d:%02d`, because
   milliseconds ticking make the same countdown read as faster.
4. **Two paths.** *("two paths it is.")* Two chains of the shape above, one ending at the tunnel
   at the north end of the main road and one at the bridge at its south end, each through its own
   three parks. They part at the service exit, or as near it as the lattice allows, and do not
   overlap after that — *"no overlapping routes"* — so the choice is made once, at the door, and
   is the game's verb; the home lot sits between the two ends of the main road so neither exit is
   trivially nearer.

**And what the finale is not.** No fighting, no button — the tone rules stand: the danger is
noise, the men are the same masked men as act III's abductions, and the baby is never threatened by
anything but being woken.
