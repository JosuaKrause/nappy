# minty-quail — Does walking the far sidewalk past the hunting guard feel fair · 2026-11-24

**What to do.** Play a late day on the desktop build with four resistance tasks done, so the
checkpoint's guard hunts (the hunting roadblock, the checkpoint whose guard comes at her from day 7 once
four tasks are done, heat 4): `tools/run.sh --seed 4242 --day 8` puts a run on a day from 7 on, and
no flag sets the tasks, so the four are done in the run before that day (`--invincible` lets one
sitting take as long as that needs). Walk a street her route runs along to a hunting roadblock and past
it on the far sidewalk, then once on its own side of the street.

**Where to look.** The hunting roadblock now closes to the day's routes only its barrier, its own
sidewalk and the road, 64px, where before an 86px circle round it did. The far sidewalk is no longer
closed, so a route can run along it still inside the 180px at which the guard notices her.

**The question a run answers.** When she next plays a late day with four resistance tasks done, does
walking the far sidewalk past the hunting checkpoint guard feel fair, or does it read as a route the
day should not have handed her? The player named this a question for the Review tab (inbox #1734 in
spry-ferret).
