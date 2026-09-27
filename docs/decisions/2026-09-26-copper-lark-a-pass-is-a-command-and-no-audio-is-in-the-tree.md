## Copper lark — A pass is a command, and no audio is in the tree · 2026-09-26

*([The sound playtest](../playtests/2026-09-26-copper-lark.md): "I'm a bit irritated by having to
download an index.html each time. is there a better way to approach this? other than that we can
merge it but delete all the artifacts before I don't want them in tree" · "yeah I'd prefer a local
command" · "same as with the trailer / video" · on the per-pass generator copies: "okay if they're
not worth let's remove them" · "yes 384 will get squashed so no scrubbing necessary".)*

GitHub serves a committed `index.html` as text, so every audition meant downloading and unzipping a
kit. `tools/sound-lab.sh` builds the current pass from the committed generator into git-ignored
`build/sound-lab/` and serves the listening page on localhost (`--lan` for a phone on the same
network), the way PR #370's `tools/trailer.sh` builds the trailer. The evidence folders with their WAVs,
zips, pages, manifests and generator copies are deleted, and the PR lands squashed, so none of it
reaches `main`'s history.

**Only the current pass rebuilds.** Passes 1 to 3 were built by generator versions that exist only
on the PR branch's own commits, which a squash leaves out of `main`; keeping them alive would need a
tag on those commits, and they were rejected auditions. Their findings are the records below.
Pass 4 rebuilds byte for byte from the committed generator, and its comparison carries the pass-3
references.

**The findings, pass 4 as the current proposal**: steps with a softer contact, 8.5 dB below pass 3;
wheels with restrained ticks, 15.5 dB below pass 3 and 7 dB below the new steps; targets of -31 and
-38 dBFS RMS, the assistant's proposals awaiting the player's ear; the grounded direction over the
stylized one; a requested level hierarchy survives the finishing stage rather than being
equalized. Audio stays a standalone experiment with no runtime integration.
