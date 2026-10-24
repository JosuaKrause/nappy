priority: now
after: 2026-10-18-minty-quail

# lilac-marten — After the refactor: a fuller escape, every charger warning shorter with a larger radius, total time on the ending screens, then v0.30.0 · filed 2026-10-24


Said right after v0.29.1 shipped, "for after the refactor" (curly-moose #803): "the escape is
basically empty now. the charging timins are off -- the warnings should be shorter and the radii
slightly larger. the end screen doesn't show the total game time -- only the current day's
completion time. *all* end screens must show both". Corrected when an agent read the chargers too
narrowly and the screens too widely: "I'm talking about *every* charger in the game" (the stairwell
guard "is the exception to the regular warning anyway"), and "I'm talking about *ending* screens
*not* day/scene completion screens (those keep their segment's time)"; told the escape roadblock
guard notices her within 180px and warns for 2.0s, "yes 180px is way too small and 2s is too long
-- *in general*" (curly-moose #803).

**Items, after minty-quail (one engine):**
- **The escape's city is fuller.** More dangers than the bag v0.29.1 shipped places; this bears on
  the open review item `docs/review/2026-10-18-downy-tapir.md` (whether that bag stays the climax or
  becomes two draws a street), so its answer is read first.
- **Every charger warns for less time and notices her from slightly farther away**, the stairwell
  guard's own warning excepted. **Read as:** `Tuning.CHARGER_WARNING` (2.0s, read by every waiting
  charger) goes down and every charger's notice radius goes up "slightly", and 180px is "way too
  small" in general; the new numbers are the builder's proposal under **balance**, shown to the
  player before they ship.
- **The screens that end the game show the total game time** beside their segment's time; a day's
  or a scene's completion screen keeps its segment's time only.

**Then a minor release:** "After the refactor and the fixes from the last playtest let's cut a minor
release" (curly-moose #803) is the player's go-ahead for v0.30.0 once minty-quail is closed and
these three have landed. **Open:** whether snowy-goose (explosions in the escape city), from the
same playtest file, is among "the fixes" the release waits for.
