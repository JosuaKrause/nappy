Find what costs the long frames on the phone's web build and fix it. Start from a saved frame
record of a spike on the phone (the review item asks the player for one, day 12 after the park with
the baby asleep among them) and name the system its longest frames spend on (every phone frame is
over the 25ms `slow` line). Without one, bisect back from v0.25.4 (the softlock was met by
2026-10-06, so the release that brought it is that one or older) to a release without the long
frames, on the desktop web build in Chrome at a phone's CPU throttle with the frame record on, on
day 12's park sequence and a busy day, comparing the longest frames' systems between releases; the
throttle shows what is sensitive to a slower CPU but does not stand in for a phone (M159's caveat).
Fix the cause, with a measurement before and after on the same seed and route, and a check where
one can catch a return (a probe under `tests/probes/` at least). Report whether the day-12 softlock
of azure-koala, finding 9, was this.
