## M60 — What the live site changed · 2026-09-02

**The first deploy went green on its first run** — gate, export, upload, publish — and
`https://nappy.josuakrause.com/` served the game: 5.4 KB of HTML, a 39.5 MB WASM binary, a 950 KB
pack and a 280 KB loader. That run is also the first time the Web export completed anywhere.

**Then it was played, and two things had got through the dev-flag gate.**

**The developer's readout was on screen for the whole run, in every build**, and the cause is worth
keeping because it is a shape rather than an oversight: `main._open_the_title()` hid the readout and
`_on_title_start()` — which fires every time the player presses space — set it back to an
unconditional `true`. A gate applied at one of two sites is not a gate. It is now read once into a
member both sites and `_ready()` share, the string is not assembled at all outside a debug build
(the readout scans every live event for its "nearest" line, sixty times a second), and
`tests/test_main.gd` drives `_process()` with that member flipped both ways.

**`Q` quit on a platform where quitting does nothing.** `SceneTree.quit()` on a Web export leaves
the tab exactly where it was, so the key was a screen telling the player to press something and
watching it fail. `QuitOption.available()` is the single answer, and **the axis is the platform, not
the build** — a debug web build has the same dead quit as a release one, which is the same axis the
run log already uses to stay silent on the web. *(Player, 2026-09-02: "**only** for the online
version, for the local version Q needs to exist still.")* The pause screen needed a second fix on
the way: its hint was never set in code at all, only baked into the scene, so it could not have
varied. Both scene files now bake only the half that is always true.

**And the window letterboxes.** *(2026-09-02: "everything that doesn't fit the aspect ratio should
be filled in with black bars.")* `window/stretch/aspect` was `expand`, so a wider window showed
**more city**. That is a fairness change and not only a framing one: `DangerEdge` — the chevrons
warning about what is coming while it is still off screen — is measured in screen pixels and asks
*is this on screen*, so a 21:9 monitor bought more warning than a laptop, on nothing the player did.
`keep` is the value that bars **both** axes; *rejected: `keep_width` and `keep_height`, each of which
letterboxes one axis and keeps growing on the other.* `tests/test_danger.gd` now pins the setting, so
a silent revert fails a test rather than only a screenshot.

**One brief was wrong and the agent caught it.** The letterbox agent was pointed at a `TODO.md` entry
that did not exist on its base — the entry had been written on an unmerged branch. It grepped the
whole queue, the archive and the playtests for it, found nothing, proceeded on the self-contained
specification in its prompt, and said so. That is the fork rule working in the direction that is
hardest to notice.
