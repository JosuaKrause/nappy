# Playtest 27 — 2026-09-06

The second session on the released page, played on both a laptop browser and a phone, given as
notes in one conversation. **Six findings and one of them is a design.** Five are things that are
wrong — a build that does not arrive, a control scheme that does nothing on a desktop, a press that
is not acknowledged, a pair of buttons still missing, and a shared link with no picture. The sixth
is an alternative control scheme the player wants to try, specified in full.

**Two of the five are diagnosed here and the diagnosis is from reading, not from running.** Where
that is the case it is said so in the finding.

---

## 1. The browser does not come back with the newest release

> "the browser doesn't automatically refresh to the newest release I think the caching is not based
> on etag?"

**The player's guess is right in effect, and the mechanism is one step to the side of it.** GitHub
Pages does send an `ETag` for every file on the site, and it sends `Cache-Control: max-age=600`
alongside it. `max-age` is what decides whether the browser *asks at all*: for the first ten minutes
after a file is fetched the copy on disk is considered fresh, and the browser serves it without ever
opening a connection, so the `ETag` it holds is never offered and never compared. Revalidation only
begins once the ten minutes are up. So the page is not refreshing on an `ETag` because on a reload
inside that window there is no request for an `ETag` to be attached to.

**The four files that make up the game expire independently, and that is the worse half.** The
export is `index.html`, `index.js`, `index.wasm` (39.5 MB) and `index.pck` (2.4 MB), all four served
under fixed names that never change between releases —
`GODOT_CONFIG` in the generated `index.html` names `"executable":"index"`, and the engine appends
`.wasm` and `.pck` to it. Each file's ten minutes starts when *that* file was last fetched, so a
reload part-way through can take a fresh `index.html` and `index.js` against an `index.pck` and an
`index.wasm` from the previous release. That is not a stale build; it is a **mixed** one, and there
is nothing that would report it as anything other than the game behaving strangely.

**Nothing on GitHub Pages can set a header.** There is no `_headers` file, no `.htaccess` and no
configuration surface — `max-age=600` is what the host sends and it cannot be changed from this
repository. So a fix has to be in the URLs rather than in the headers: **the file names have to
change when the release changes**, which is the one thing that makes a cached copy irrelevant rather
than merely stale.

## 2. Tap mode does nothing on a laptop browser

> "tap mode doesn't work on a laptop browser. I click on the tap button and I have to use keyboard
> anyway."

**Diagnosed by reading `src/ui/tap_controls.gd`, not by running the released build.**
`TapControls._input()` reads two kinds of event. A real finger sends `InputEventScreenTouch` and is
always read. A mouse click sends `InputEventMouseButton` and is read only behind
`OS.is_debug_build() and not _touch` — the comment on that branch says what it was for: *"on
non-mobile we can try clicking with the mouse instead of tapping" is a way to try the mode out on a
desktop, not a control an exported build owes a mouse.*

**The published page is a release export.** `tools/export-web.sh` with no argument exports release
and is what `.github/workflows/deploy.yml` runs, so `OS.is_debug_build()` is false there and the
mouse branch is dead code on the only build a player ever loads. Choosing tap on a laptop therefore
selects a scheme with **no input at all** — the keyboard still presses `move_*` directly, which is
why the keyboard is what the player was left with.

**And this is invisible to every local check.** `tools/serve-web.sh` is the only way to run the web
build without deploying it, and it exports **debug** on purpose, which is the one build where the
mouse branch is live. The mode works on every machine it has ever been tried on and on none that
anybody plays.

**The decision it collides with is written down in that same comment** — that an exported build owes
a mouse nothing. What has changed underneath it is that the title screen now *offers* tap as one of
two buttons on a desktop, so a laptop player is invited to choose a mode that cannot be played. The
comment's decision was taken when the only way to reach tap mode was a URL parameter somebody had to
know about.

## 3. A press on the phone is not acknowledged, and the wait after it is long

> "I tried on mobile and one thing we need to fix is that after pressing a button there is a
> significant delay before the game starts/resumes. we need to indicate that the button press is
> registered."

**Two things in one sentence, and the player asks for the second.** The complaint is the delay; the
design is *indicate that the button press is registered*. The design stands whatever the delay turns
out to be, because a press with no acknowledgement reads as a press that missed, and the player's
next move is to press again.

**What is known about the delay, from reading rather than from measuring.** Day one is placed during
boot — `main._ready()` calls `_start_day()` at the end of it — so the title screen's own start is
cheap and is not obviously where a wait comes from. Two other transitions do real work
synchronously, on the frame the button is pressed:

- **Continuing from a day summary** runs `main._start_day()`, which plans the day's closures,
  places every event, and streams the world around the doorstep before the next frame is drawn.
- **Restarting** runs `main._restart_run()`, which reloads the whole scene, and re-entering
  `_ready()` regenerates the city from scratch — the step `main` already times and prints as
  `[Main] city generated in N ms`.

**None of that is measured on a phone**, and a fourth candidate is the browser rather than the game:
a Godot web export's first frames after a screen closes include shader compilation and texture
uploads that a desktop finishes without anybody noticing. **The cause is an investigation, and it
does not block the acknowledgement**, which is what was actually asked for.

## 4. There is still no continue and no restart button

> "also there is still no continue and restart button in the pause or death screen"

**A re-report, and the thing being re-reported is designed, queued and unbuilt.** It is the second
item of **M76** in `docs/TODO.md`, which owns both screens with one pair of buttons: **continue** as
a tap, suggested as an arrow to the right, and **restart** as a *hold* that fills a bar over about a
second, suggested as a circular arrow. That entry already carries the reasoning, the two earlier
askings it comes from *(2026-09-05: "we need a dedicated button for restart from the pause menu";
2026-09-06: "on the day end and pause screen show two buttons continue … and restart game …")*, and
the trap it has to avoid — both screens currently read **any** touch as *carry on*, so a held button
has to be tested against the touch position before that branch.

**Nothing here is designed again.** M76's first item — the title screen's two buttons — was built
and released; the second was not. This finding is closed from that entry rather than given one of
its own, and what it adds is a third asking, which is the measure of how visible its absence is.

**It is also the same complaint as finding 3.** The pair of buttons is what there is to acknowledge
a press on; a screen whose only control is "tap anywhere" has nothing that can light up.

## 5. The social card image does not load

> "the social media images don't load. are they properly set? compare with josuakrause.com"

**The image itself is published and reachable.** `https://nappy.josuakrause.com/social-card.png`
answers `200` with `Content-Type: image/png` and 49,894 bytes for an ordinary browser and for each
of `facebookexternalhit`, `Twitterbot`, `WhatsApp` and `Slackbot-LinkExpanding`, so neither the
deploy step that copies it nor the host is dropping it. The `og:` tags are in the head and the
`og:image` is an absolute `https://` URL. **Whatever is wrong is in what the markup does not say, or
in the file's own format, rather than in a missing file.**

**Four differences against `josuakrause.com`, which is the comparison the player asked for**, in the
order they are worth trying:

- **The card is RGBA and the reference is RGB.** `assets/logo.png` is `PNG image data, 1280 x 640,
  8-bit/color RGBA` — it carries an alpha channel. `https://www.josuakrause.com/img/photo_675x630.png`
  is `8-bit/color RGB`, with no alpha. A transparent PNG is the classic reason a card image is
  dropped or rendered as a black rectangle by a link unfurler, and it is the one difference here
  that is about the file rather than the markup.
- **The dimensions and type are not declared.** `josuakrause.com` sends `og:image:type`,
  `og:image:width` and `og:image:height`; this page sends none of the three. Several unfurlers will
  skip an image they would otherwise have to fetch and measure themselves.
- **There is no `twitter:image`.** This page sets `twitter:card` to `summary_large_image` and then
  names no image under the `twitter:` prefix at all, leaving the fallback to `og:image` to whichever
  client is reading. `josuakrause.com` sets `twitter:image`, `twitter:title`, `twitter:url` and
  `twitter:domain` explicitly.
- **There are two `<title>` elements.** Godot's own shell writes `<title>Nappy</title>`, and
  `html/head_include` in `export_presets.cfg` adds a second, longer one after it. A scraper that
  takes the first title gets `Nappy` rather than the sentence that was written for it. This does not
  explain a missing image and it is wrong on its own account.

**It failed in a messaging app** *(2026-09-06, asked where they saw it: a messaging app —
WhatsApp / Signal / iMessage)*, which is the family of unfurler that the first two differences are
about. A messaging preview is rendered by a client with no patience for an image it has to fetch and
measure itself, and a transparent PNG is exactly what those clients drop or paint black. **All four
are worth doing regardless**, and that answer says which two to do first.

---

## 6. The design: an alternative joystick mode

> "since the tap mode now works really nice I want to try an alternative joystick mode. the joystick
> moves more towards the middle vertically and a little bit more inside from the left. as long as
> you tap left of 2/3 of the screen the direction relative to the center of the joystick drawing
> gets locked in and becomes the direction. running is still the dedicated running button and pause
> is still in the top right. stopping movement can be done by tapping on the center of the big
> joystick circle (doesn't have to be dead on -- create a tappable area the size of the small
> joystick circle)"

**It is a joystick that is aimed at rather than dragged.** The drawing stays a joystick and stays
where a left thumb rests, but the thumb no longer has to find it: a tap **anywhere in the left two
thirds of the screen** is read as a direction — the vector from the drawn joystick's centre to
wherever the tap landed — and that direction is **locked in** and walked until something else
changes it. The stick is a compass rose the whole left of the screen aims through, rather than a
thing to be gripped.

Every specific the player gave:

- **The joystick moves.** *"more towards the middle vertically and a little bit more inside from the
  left."* Today `TouchControls.STICK_CENTRE` is `(130, 500)` in the fixed 1280x720 design box, so
  both moves are from there: up toward 360, and right from 130.
- **The catch region is the left two thirds of the screen**, not a radius. *"as long as you tap left
  of 2/3 of the screen."* Two thirds of the 1280-wide design box is x < 853.
- **The direction is measured from the drawing's centre**, not from the previous touch and not from
  the player. *"the direction relative to the center of the joystick drawing."*
- **It locks in.** *"gets locked in and becomes the direction"* — she keeps walking it with nothing
  held down, the way a tap's heading in tap mode is fixed once and never re-aimed.
- **Stopping is a tap on the joystick's own centre**, with a generous target: *"doesn't have to be
  dead on -- create a tappable area the size of the small joystick circle."* The small circle is the
  knob, `TouchControls.STICK_KNOB_RADIUS`, 24px — so a 24px-radius stop button at the joystick's
  centre.
- **Running is unchanged**: *"running is still the dedicated running button"* — the RUN button at
  `(1150, 500)`, held, on the right third of the screen where no aiming tap can reach it.
- **Pause is unchanged**: *"pause is still in the top right"* — `(1218, 62)`, also outside the left
  two thirds.

**Two things the sentence did not say went back to the player rather than being inferred, and both
were answered in the same session, before anything was built.**

**It replaces the drag stick, which is deleted.** *(2026-09-06, asked whether this was a third
scheme or a replacement: "replaces the drag stick".)* The title screen keeps exactly two buttons and
the joystick one now selects this scheme; there is no way left to drag the stick, and no third path
to keep alive. The joystick glyph on the title button still tells the truth, because what it selects
is still a joystick — it is aimed at rather than gripped.

**Distance from the centre sets nothing; every aiming tap is a full-speed walk.** *(2026-09-06,
asked whether the tap's distance was a deflection: "no — direction only, full speed".)* So the
scheme presses a unit vector the way a tap-to-walk leg already does. With the whole left two thirds
of the screen as the target, how far out a thumb lands is mostly an artefact of where it happened to
fall rather than something the player meant.

**And the answer came with the rule underneath it, which is bigger than this scheme:**

> "there is no way to walk slowly -- that is intentional -- there should only ever be one speed
> (plus a second via running)"

**The game has two speeds and no others**: `Tuning.WALK_SPEED` (92 px/s) and `Tuning.RUN_SPEED`
(168 px/s), and running is a held button rather than the far end of any gradient.

**Today the drag stick is the one thing that breaks it.** `Stroller._physics_process()` moves toward
`input_dir * top_speed` with the **raw** `Input.get_vector(...)` rather than a normalised one — the
comment there says so, because running must never be reachable by pushing a stick further. On a
keyboard `get_vector` of four digital actions is always a unit vector, and `TapControls` presses the
components of a unit heading, so both are always exactly 92. `TouchControls._update_stick()` is the
exception: it presses `offset.limit_length(60) / 60`, so a thumb resting half way out walks her at
46 px/s.

**That is not only a question of feel; it quietly falsifies the fairness numbers.** Every lead time and
stand-off in `src/autoload/tuning.gd` is computed against `WALK_SPEED` as *the* walking speed — a
pursuit speed is required to sit strictly between `WALK_SPEED + PURSUIT_MIN_MARGIN` and
`RUN_SPEED - PURSUIT_MIN_MARGIN` (112 to 148 px/s), so that walking away always loses ground slowly
and running always gains. A player half-deflecting the stick is outside every one of those
guarantees and nothing tells them.

**Deleting the drag stick is therefore what makes the rule true**, rather than a separate piece of
work: with it gone there is no input path left that can press a partial vector.
