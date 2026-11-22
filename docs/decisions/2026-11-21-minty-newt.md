# minty-newt — The events' looks are handed the drawn view, as the crowd is · 2026-11-22

**What was asked.** Fable's design `drawn-view-handed.md`, from its review of #1569 (`DrawnView` stands in the world
beside `VisibleView`), a pull request of polite-tapir whose design Opus wrote in Fable's place; the player, shown Fable's
six verdicts, asked for each change to be built and Fable to review it again (the record calm-lemur). Its hand-in path
was rewritten by Fable's review of amber-dolphin to go through the events' surroundings built once. Built as #1638 by a
Sonnet agent, reviewed adversarially, then by Fable against its design.

**What was built.** `DrawnView` is an object: a view with no screen, or the screen an anchor's viewport shows, whose box
is worked out once a frame in its own fields; the statics and the metadata memo are gone, with no forwarder. `main`
makes one and hands it to the simulation builder, which hands it to the crowd's screen view (a required argument) and
puts it in the events' surroundings; each live event hands it to its look, whose two gates ask it. A suite hands a
stand-in view in place of a viewport and a frame wait.

**Differences from the design:** the car's look has a constructor of its own between the base look and the looks'
factory, a fourth look file the design's cost line did not name; it takes the view and passes it up.

**Measured.** On main and the branch: the screen-reads fingerprint byte-identical, and the run log of a headless day
that walks her to her mark into a forced charging dog identical line for line but one badge distance, which varies run
to run on both sides with frame timing.
