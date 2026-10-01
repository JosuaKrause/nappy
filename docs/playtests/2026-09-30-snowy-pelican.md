# Playtest snowy-pelican — Implement nearby scenery loading and unloading

2026-09-30.

## Implement the recorded scenery policy

PR #444 records the preparation, memory and generated-route coverage investigation, with
nearby scenery preparation and distant unloading retained as M159's implementation item. The
player asks to build that policy:

> let's implement the lazy loading/unloading

The assistant says it will use freeable ground chunks, preserve gameplay and reconstruct
current visual state on revisits, and measure preparation cost and walking performance. The
player points to the existing investigation:

> the measurements were already done, no? in 444

The assistant confirms that #444 supplies the preparation-time, memory and actual-route
baseline. New checks concern the implementation: loading ahead of the camera, unloading with
the wider retention boundary, avoiding repeated preparation at the loading edge, restoring
changes made while scenery is absent, and avoiding gaps and walking hitches. The existing
investigation is not repeated.

## Retain and publish the generated evidence

Automatic approval review rejects uploading the generated 21.5MB evidence set to GitHub,
citing lack of explicit approval and incomplete verification that the payload is non-sensitive.
The assistant keeps it local and reports the rejection. The player asks:

> what is the nature of the captures? images from the game? videos from the game?

The assistant explains that these are game captures only: 72 screenshot frames from two
short gameplay bursts, two generated map images and two MP4 clips from those frames. The
remaining files are two rig logs, three JSON files and a README. The runs are scripted test
runs, with no desktop footage or player save files. The player asks about redundancy:

> so if you have mp4 clips do you need the original frames anymore? or vice versa? which one uses less space? which one can be read more easily?

The assistant says MP4s are smaller and easier to review as motion, while PNGs preserve exact
pixels and are easier for the assistant to inspect for seams and missing scenery. It proposes
clips plus representative frames, then checks actual sizes and the rule requiring the whole
run folder. The player asks:

> how big are rig logs?

The assistant reports 6.4KB and 5.7KB for the logs, 12KB combined; 1.59MB for both MP4s and
19.87MB for all 72 PNG frames. With that context, the player chooses to retain and publish
the complete evidence set:

> let's keep everything for now and push

## Finish CI in the implementation PR

The assistant says it will push the complete evidence set and finish the documentation and
independent review. The player asks:

> what about the failing CI?

The assistant checks the current failed run. The queue/decision-record gate is pending, and
one test shard fails because the route-tint fixture assumes all ground is loaded. The other
seven shards and boot pass. The assistant commits to fixing the test without weakening its
full-route assertions and finishing the documentation gate inside this PR.
