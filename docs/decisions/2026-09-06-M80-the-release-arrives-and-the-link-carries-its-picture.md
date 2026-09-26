## M80 — The release arrives, and the link carries its picture · built 2026-09-06

Playtest 27's first and fifth findings, both about the published page rather than the game, and both
checked with `curl` against the live site rather than with the suite.

**The stale build was a `max-age`, not an `ETag`.** *"I think the caching is not based on etag?"* —
right in effect. GitHub Pages sends both, and `Cache-Control: max-age=600` is what decides whether
the browser asks at all: inside those ten minutes the cached copy is fresh, no request is made, and
the `ETag` is never offered. **The half the guess did not reach is the worse one**: the four
exported files keep fixed names between releases and each one's window starts when *that* file was
fetched, so a reload mid-window can pair a fresh `index.html` with the previous release's
`index.pck`. That is a **mixed** build, not a stale one, and it presents as the game behaving
strangely rather than as anything anybody would call a cache problem. **Pages has no header
surface** — no `_headers`, no `.htaccess` — so the fix had to be in the names.

**The design named one constraint and missed a second that would have broken audio.** It held that
the engine builds the wasm and pack URLs by concatenating `GODOT_CONFIG.executable`, so a path
prefix carries both where a query string could not. True. What nobody had checked is that the same
`loadPath` also names `godot.audio.worklet.js` and its `.position.` variant through Emscripten's
`locateFile` hook, read the instant audio initialises — **versioning the directory without moving
those two would have 404'd the first sound the game plays**, on a path no test covers. Found by
reading the exported `index.js` rather than trusting the brief, and confirmed by fetching both from
a served export in a real browser.

Every anchor in `index.html` is asserted to occur exactly once before it is rewritten, so a future
Godot shell that renames one fails the export loudly rather than shipping a page pointing at the
wrong place.

**The card image was never missing.** It answered 200 with `Content-Type: image/png` for an ordinary
browser and for `facebookexternalhit`, `Twitterbot`, `WhatsApp` and `Slackbot-LinkExpanding`. **The
cause is the alpha channel**: `assets/logo.png` is RGBA and its transparent pixels carry RGB
`(0, 0, 0)`, verified pixel-wise, so a messaging client that ignores alpha paints the card **black**
— which is what *"the images don't load"* looks like from the outside. The player's answer that they
saw it in a messaging app is what ranked that above the other three differences from
`josuakrause.com`.

**Flattened once and committed rather than at deploy time**, which was the milestone's other offered
option: ImageMagick is no longer preinstalled on `ubuntu-latest`, and a `pip install Pillow` step
would hit PEP 668's externally-managed-environment restriction without a venv. `assets/logo.png` is
untouched, since it is also the README's image and transparency is right there.

The other three: `og:image:type`/`width`/`height` declared, because a client that would otherwise
have to fetch and measure the image often skips it; `twitter:image` and `twitter:title` added, since
the page declared `summary_large_image` and then named no image under the `twitter:` prefix at all;
and the duplicate `<title>` removed. Godot's own shell writes `<title>Nappy</title>` *before*
`html/head_include` is appended, so a scraper reading the first title got `Nappy` rather than the
sentence written for it — stripped from the shell's side during the export, since the include's
title is the one meant to survive.

**Left open and cheap to overturn**: `RELEASE_TAG` versions the **debug** export too, so
`tools/serve-web.sh` serves from `build/web/dev/`. One code path rather than two, and no downside
was found.
