# Playtest 69 — 2026-09-13

A test run of v0.10.0 on the desktop, played with the frame readout on, right after the release.

## It looks good

> okay I did a test run looks good.

The round that shipped — the events' redraw gate and the chunked shadows, the first press no
longer walking her, the readout — passed a play without a complaint.

## People still come out from outside the map

> one thing I noticed is people still come out from outside the map

A re-report. [PLAYTEST-66](PLAYTEST-66.md) asked for this — *"while people or cars cannot
leave the map anymore from non-tunnel/bridge edge locations they can still spawn there and
walk/drive out of nowhere"* — and M120 answered it (`DECISIONS.md`, M120, the map edge): a
recycled walker or off-spine car is given no room past the true edge at all, so its entry roll
never leaves the map, and only a spine car keeps its room through the tunnel or off the bridge.
On v0.10.0 walkers are still seen coming in from beyond the edge. Filed as a defect under M100
in `TODO.md`, with the suspect the code shows: beside a plain edge the entry band collapses to a
single point on the boundary line itself, and a walker whose centre is on that line has half its
picture outside the map and walks inward from it — which is *coming out from outside*, whatever
the centre's coordinate says. The `REVIEW.md` item that asked about the edge closes on this.

## The social card unfurls

> this is how the social media preview looks like on whatsapp

A screenshot, `evidence/playtest-69-social-card-whatsapp-2026-09-13.jpeg`: the card on a white
ground with the stroller icon, the wordmark, the tagline *"Fourteen days. One pram. Get her to
sleep and get her home."*, then the title and description under it. The unfurl that failed
black before M80's flattening (`DECISIONS.md`, M80) now comes back whole in a chat client; the
`REVIEW.md` item that waited on exactly this closes.
