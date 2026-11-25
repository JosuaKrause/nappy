# minty-quail — Check the frame-record save button and a held restart on the published page · 2026-11-24

**What to do.** On the published page, once a release carries minty-quail, open it with
`?debug=1&framerecord=1`, play a minute and press the `save frames` button at the top of the page;
a local export from `tools/export-web.sh` served with `tools/serve-web.sh` does the same before a
release. Then, on the same page without the frame-record query, play to a point where the game has
just saved (a day's end or a checkpoint) and hold the restart on the pause screen at once, in a
tab on a slow connection or with the browser's storage throttled so the flush is still pending.

**Where to look.** The browser's download folder for the frame record, and that the button still
saves it after the game's scene has reloaded. For the restart, the title or day the restart lands
on and whether the run you restarted from is the one the save holds.

**The question a run answers.** Does the frame record's save button, whose callback the recorder
holds across a scene reload, still hand the browser a file after a reload, and does a restart
held while the save's flush is pending lose or keep the run, with the save node the sitting
keeps? Both were read off the code when they were built (minty-quail-fluffy-lark and
-striped-quail) and not run in a browser.
