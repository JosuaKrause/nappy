**The page says the frame record was saved when its save button is tapped.** Build the feedback
the README proposes on the button the page draws, check it in desktop Chrome on a release export
with `?debug=1&framerecord=1` (a still of the button before and after the tap, embedded in the pull
request), and update `docs/TELEMETRY.md`'s "Per-system frame records" with what the page shows.
The desktop's write under `user://frame-records/` already prints its path and is unchanged.
