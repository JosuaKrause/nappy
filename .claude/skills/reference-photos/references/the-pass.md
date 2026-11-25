# What the pass does to a file, and how it fails

Read this before changing `tools/reference.sh` or its Python, and when a run's output has to be
read: what happens to every file and why none of it has an opt-out, and what the script needs.

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

## Failure is loud, and that is the contract

The script exits non-zero and names every file it could not handle — a missing input, an
unreadable source, an ffmpeg that is not installed, an output that did not appear or came out
empty, a name already taken without `--force`. **A pass that silently converted nothing looks
exactly like a pass that worked**. Read the output; a partial run is
a failure.

**Videos need `ffmpeg` on `PATH`.** Stills need only the locked Python environment, which
`uv run` builds from `pyproject.toml` on first use — see the **python-tooling** rule. The reading
of HEIC comes from `pillow-heif`, which is in that lockfile because an iPhone photo is HEIC and
Pillow cannot open one without it.
