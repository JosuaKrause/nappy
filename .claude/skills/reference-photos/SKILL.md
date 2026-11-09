---
name: reference-photos
description: How a real-world photo or video gets into the repo as drawing reference, or an approved illustration-style reference gets added — which of the two folders each goes in, the shrink-and-strip pass every file goes through, and what may not be committed at all. Load this BEFORE adding any photograph, phone video, camera capture or style reference to the repository.
---

# Real-world reference and style references

**The rules not to miss:**

- **A file enters `docs/reference/` or `docs/style-references/` only through `tools/reference.sh`**,
  never copied by hand.
- **Every file is shrunk and stripped of all metadata, and a video loses its audio**: the
  repository is public.
- **Rename it to `<subject>-<detail>-NN.<ext>` before the commit**: a camera stem is a timestamp.
- **Name the field, never the value**: nothing republishes what the pass stripped.
- **Import first, then write about it**, by the name it is committed under (woolly-walrus #516).
- **Never commit a file there is no right to redistribute, or a recognisable person who did not
  agree to it.**
- **A partial run is a failure**: read the script's output.
- **An agent's sparse worktree leaves both folders out**: a new file there is committed with
  `git add --sparse <path>`.

**Reference material goes in `docs/reference/`, an approved style reference goes in
`docs/style-references/`, and both get there through `tools/reference.sh`.**

```sh
tools/reference.sh ~/Desktop/pram-on-a-kerb.heic
tools/reference.sh ~/Pictures/street-walk/          # a whole folder
tools/reference.sh --style ~/Desktop/new-illustration-ref.jpeg   # into docs/style-references/
tools/reference.sh --force one-that-is-already-there.jpg
```

**Never copy a file into either folder by hand.** Everything below is what the script does, and a
hand-copied photo has none of it — which is not a tidiness problem, because the second guarantee
is a privacy one.

**The script takes a path, so a picture pasted into the conversation cannot be imported**: it has
no file behind it. What to do when a picture arrives with no path (ask where it is saved, never
describe it instead) is a rule about the conversation, and `CLAUDE.md` holds it.

**An agent's sparse worktree leaves both folders out.** A new file under `docs/reference/` or
`docs/style-references/` is committed with `git add --sparse <path>`, and a task that reads the
photographs asks for a worktree made with `tools/agent-setup.sh ... --include docs/reference/`.

## What the folder is, and what it is not

**Reference is an *input to drawing*: a photograph of the real thing, held up next to the art.**
The folders that hold pictures are not interchangeable:

- **`docs/reference/`** — the real world. Never shipped, never shown, never cited as proof of
  anything. It exists so a sprite can be drawn from something rather than from memory.
- **`docs/style-references/`** — the approved illustration-style references
  (`graphics-reference-*.jpeg`) that illustrated-png draws from: flat, no subfolders, added
  through `tools/reference.sh --style`. See `docs/style-references/README.md` for what each file
  is a reference for.
- **Everywhere else is something else.** `docs/evidence/` is the game, captured, plus the
  generation records, review sheets and provenance that point at the style references above. It is
  proof: a doc sentence points at it, and the **playtest-feedback** skill's rule requires the
  picture to land in the same commit as the sentence; how its folders are named is the
  **session-captures** skill's. `art/` holds the authoring pictures the atlas bake reads, of which
  only `art/social-card.png` ships, copied by `.github/workflows/deploy.yml`; `assets/` is what the
  engine reads at runtime, and only that.

**`docs/.gdignore` keeps the engine out of both folders, and it is the one not to delete.** Neither
folder carries a `.gdignore` of its own, since the one in `docs/` covers every folder under it; what
a `.gdignore` does and why no `.import` sidecar is written there is the **godot** skill's,
"Structure".

## What the pass does

Every file is **shrunk to fit inside 1280x720**, the game's own design box, never enlarged; **every
scrap of metadata is dropped**, by re-encoding through fresh pixel data, because a phone photo
carries GPS coordinates, a device serial number and a capture time and this repository is public;
and **a video loses its audio track and drops to 15fps**. Each is a rule rather than a default, and
none has an opt-out flag. The script exits non-zero and names every file it could not handle, and
**a partial run is a failure**. The reasons in full, the output formats and what the script needs
installed are `references/the-pass.md`.

## Then rename it, and that is not optional either

**The tool slugifies; it does not name.** `IMG_4821 (2).HEIC` becomes `img-4821-2.jpg` — lowercase,
hyphens, safe in a URL and a shell — because nothing in a converter can know what a picture is of.
**Renaming to say what the thing is happens before the commit**, and there are two separate reasons.

**A camera stem is usually a timestamp, and that is the metadata the pass just removed.** Google's
is `PXL_YYYYMMDD_HHMMSSsss`, in UTC to the millisecond. Stripping the tag and
keeping the filename **puts the capture time back**, in the one place `ls` shows it. Apple's
`IMG_####` and Canon's `DSC#####` are only counters rather than clocks, but they are equally
useless, so the rule is one rule.

*(The format, not an example: see "Never republish what the pass just stripped" below — a real
stem here would be a real timestamp, published to prove that publishing timestamps is bad.)*

**And reference is opened by subject.** Somebody is drawing a barricade, or a crosswalk, or a
rooftop duct, and the folder is worth having only if typing that word finds it.

**The scheme is `<subject>-<detail>-NN.<ext>`**, plain English, no date, no device, a two-digit
counter that is unique within a subject across extensions — so a still and a video of one scene
never share a stem, which the tool would read as a collision:

```
road-closed-barricade-01.jpg
street-corner-crosswalk-01.jpg      street-corner-crosswalk-02.jpg
storefront-row-taco-bell-01.jpg     bus-articulated-at-stop-01.jpg
rooftop-ducts-over-street-01.jpg    rooftop-ducts-over-street-02.mp4
```

**No date, deliberately, and this is where reference differs from evidence.**
`docs/evidence/shot-2026-09-07-seed4242-halo-sprite-outline.png` earns every field it carries,
because evidence exists to be *reproduced* and the date and seed are how. Reference is never
reproduced; it is looked at. A date on it sorts the folder by when somebody happened to be out with
a phone, which answers a question nobody asks.

**Do not name a file after the `EventDef.Look` it is reference for.** `look-barricade-01.jpg` reads
as the strongest possible link to the code and is a trap twice over: most frames are reference for
several rows at once, and a filename tied to an enum member has to be renamed whenever the enum
moves.

## Files are ingested before anything is written about them

**When the player hands over photos or videos, they are imported first, and only then talked about
in anything that lasts.** The originals are never uploaded, so anything written about them before
the import (woolly-walrus #516) is stale at once, with nothing to reference. An inbox note, a brief,
a queue entry or a pull request names a file by the subject name it is committed under, or describes
it by what it shows; never by the local path or archive it arrived in, its camera filename, or when
or where it was taken. The originals never reach the repository, so a reference to one is a pointer
nobody can follow, and its name and time are the metadata this pass removes.

## Never republish what the pass just stripped

**Name the field, never the value.** A commit message, a pull request description, a doc or a
report that proves the strip worked by pasting the `location=` line out of a source video has
published the coordinate the strip existed to remove — into git history and onto a public pull
request, where it outlives the file it came from and is indexed besides.

This section does not quote a value either; if an example is unavoidable, invent one.

Write the evidence as **which fields were present and that they are gone**:

> The stills carried `Make`, `Model`, `Software`, `DateTime` and eleven GPS tags apiece; the
> committed files answer `getexif()` empty.

That proves exactly as much and leaks nothing. **The same applies to a filename** — see the naming
rule above, which exists because a camera stem is usually the capture timestamp.

## What must not be committed at all

**A file you do not have the right to redistribute.** The repository is public and a reference
folder is not fair use by virtue of being called reference. Your own photographs are fine.
Something scraped off the web is not, whatever the pass above does to it.

**A recognisable person who did not agree to it.** The stripping pass removes the metadata, not
the face. If the useful part of the picture is a posture, a fold of cloth or a piece of street
furniture, that is what to keep in frame.
