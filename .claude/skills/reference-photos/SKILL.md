---
name: reference-photos
description: How a real-world photo or video gets into the repo as drawing reference — the one folder it goes in, the shrink-and-strip pass every file goes through, and what may not be committed at all. Load this BEFORE adding any photograph, phone video or camera capture to the repository.
---

# Real-world reference

**Reference material goes in `docs/reference/`, and it gets there through `tools/reference.sh`.**

```sh
tools/reference.sh ~/Desktop/pram-on-a-kerb.heic
tools/reference.sh ~/Pictures/street-walk/          # a whole folder
tools/reference.sh --force one-that-is-already-there.jpg
```

**Never copy a file into that folder by hand.** Everything below is what the script does, and a
hand-copied photo has none of it — which is not a tidiness problem, because the second guarantee
is a privacy one.

## What the folder is, and what it is not

**Reference is an *input to drawing*: a photograph of the real thing, held up next to the art.**
Three folders in this repo hold pictures and they are not interchangeable:

- **`docs/reference/`** — the real world. Never shipped, never shown, never cited as proof of
  anything. It exists so a sprite can be drawn from something rather than from memory.
- **`docs/evidence/`** — the game, captured. It is proof: a doc sentence points at it, and the
  **feedback** rule requires the picture to land in the same commit as the sentence.
- **`assets/`** — what ships. Everything under it is loaded by the game.

**The folder carries a `.gdignore`, and that is load-bearing.** Godot walks every directory under
the project and would import each photo as a texture, writing a `.import` sidecar per file and
carrying the lot into the exported build. An empty `.gdignore` is the engine's own *this directory
is not mine*. The script writes it; do not delete it.

## The three things that happen to every file

Each of them is a rule rather than a default, and none has an opt-out flag.

**1. It is shrunk to fit inside 1280x720, aspect ratio kept, never enlarged.** That is the game's
own design box — every screen is authored against it — so a reference can be held up beside a
screenshot at the same scale. A portrait phone photo comes out 540x720 rather than being cropped
or squashed, and a source already smaller than the box is left at its own size rather than blown
up to look like more detail than it has.

**2. Every scrap of metadata is dropped.** *This is the one that matters.* A phone photo carries
GPS coordinates, a device serial number, a capture timestamp and frequently an owner's name; a
PNG carries text chunks that survive every ordinary copy. **This repository is public** — it has a
released build on GitHub Pages — so committing an untouched phone photo publishes where its
photographer was standing and when. The script re-encodes through fresh pixel data, which is what
makes the strip total rather than a list of tags somebody remembered to clear.

**3. A video loses its audio track and drops to 15fps.** What a video is for here is *motion* — how
a pram turns, how a crowd parts — and the audio is the half most likely to have recorded somebody
who never agreed to be recorded. 15fps is enough to read a movement and roughly halves what the
repository has to carry.

A photo comes out as JPEG, or as PNG if the source had an alpha channel, because a cut-out with a
transparent background is a different kind of thing from a photograph.

## Then rename it, and that is not optional either

**The tool slugifies; it does not name.** `IMG_4821 (2).HEIC` becomes `img-4821-2.jpg` — lowercase,
hyphens, safe in a URL and a shell — because nothing in a converter can know what a picture is of.
**Renaming to say what the thing is happens before the commit**, and there are two separate reasons.

**A camera stem is usually a timestamp, and that is the metadata the pass just removed.** Google's
is `PXL_YYYYMMDD_HHMMSSsss`, in UTC to the millisecond — checked against a real file's own EXIF
`DateTime`, which was the same instant offset by the capture's timezone. Stripping the tag and
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

## Never republish what the pass just stripped

**Name the field, never the value.** A commit message, a pull request description, a doc or a
report that proves the strip worked by pasting the `location=` line out of a source video has
published the coordinate the strip existed to remove — into git history and onto a public pull
request, where it outlives the file it came from and is indexed besides.

**Including here.** This section does not quote the value either, and the first draft of it did:
naming the field was written down as the rule and the rule's own example broke it in the same
sentence. If an example is unavoidable, invent one.

**This has already happened here once**, in the pull request for the first batch and in that
branch's own commit message, and it was caught by the player rather than by anything in the
process. Both were rewritten; the branch was unmerged, which is the only reason the fix was cheap.

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

## Failure is loud, and that is the contract

The script exits non-zero and names every file it could not handle — a missing input, an
unreadable source, an ffmpeg that is not installed, an output that did not appear or came out
empty, a name already taken without `--force`. **A pass that silently converted nothing looks
exactly like a pass that worked**, which is the same reason this project prefers `Edit` over a
`sed` one-liner. Read the output; a partial run is a failure.

**Videos need `ffmpeg` on `PATH`.** Stills need only the locked Python environment, which
`uv run` builds from `pyproject.toml` on first use — see the **python-tooling** rule. The reading
of HEIC comes from `pillow-heif`, which is in that lockfile because an iPhone photo is HEIC and
Pillow cannot open one without it.
