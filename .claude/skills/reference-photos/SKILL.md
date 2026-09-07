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
transparent background is a different kind of thing from a photograph. Names are slugified
(`IMG_4821 (2).HEIC` becomes `img-4821-2.jpg`), so they survive a URL and a shell.

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
