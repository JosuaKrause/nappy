## M194 — The published page counts visits and how far people get · built 2026-09-25

*([PLAYTEST-132](../playtests/PLAYTEST-132.md): "can we use the same for
https://nappy.josuakrause.com/" · "let's get info about how far people get, whether they start from
a save, whether they restart, how they die, what tasks they did, etc. anything with debug doesn't
get tracked".)*

**Why GoatCounter.** The player's website carried a Google Analytics tag that sent nothing: its
snippet defined `gtag(...args)` and pushed an array, and gtag.js acts only on the `arguments`
object (a clean headless Chrome sent a `g/collect` hit with Google's own line and none with the
site's). Asked for a cookie-free counter, the player chose GoatCounter over Cloudflare Web
Analytics because only GoatCounter counts custom events, and set up one site,
`josuakrause.goatcounter.com`, for the website and the game together. The game's paths start with
its host, so the two stay apart there.

**What is built.** `export_presets.cfg`'s `html/head_include` loads `count.js` unless the query
carries `?debug=1`, with a path of host and path alone. `VisitCounter`
(`src/autoload/visit_counter.gd`) listens on `EventBus` and decides nothing; it calls the page's
`window.goatcounter.count()` for the events `docs/TELEMETRY.md` lists under "The page counts
visits": a run fresh or resumed, each day begun and how it ended, a held restart, each task done or
skipped, the ending, the escape begun, lost or got out, and the control scheme chosen. Seven
`EventBus` signals were added for it, emitted from `main.gd` with no change to play. Nothing is
sent from a debug build, on `?debug=1`, or off the web.

**Three defects found and fixed before merging**, each with a test in `tests/test_visit_counter.gd`:
a JavaScript boolean crosses `JavaScriptBridge.eval()` as an int, so a strict `is bool` check
refused every event without a word; an event asked for before the async `count.js` has loaded was
dropped, and is now held and sent with the next event; and the day-14 handover's reload onto the
save it had just written counted as a resume, then as a second fresh run, and now sends nothing.

**Choices open to overturn:** a loss is named from `GameEnums.DayResult` (`lost-crying`,
`lost-timeout`, `lost-hard-fail`); a task counts as skipped when its day ends without it done;
`nappy-escape-begun` fires on the handover from a won day 14 only, not on a reload mid-escape; the
escape and the controls are three and two flat events, with no per-section breakdown.

**Verified** with `./tools/check.sh`, `./tools/lint.sh` and the suites that touch `main.gd`,
`GameState` and the resistance; and on a release export served locally with `count.js` pointed at a
local endpoint (never the real counter): a cleared browser's first load sent `nappy-run-fresh`,
`nappy-controls-tap` and `nappy-day-1-began`, a second load sent `nappy-run-resumed-day-1`, and
`?debug=1` sent nothing. The escape handover was checked by test, not played.
