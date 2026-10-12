# plush-raven — The git-grep guard's gap is sandy-plover's · 2026-10-12

Filed from the fix on #736 (dappled-owl, the write guard sees through aliases, and only a reviewer
approves), not reported by the player: the entry said `.claude/hooks/git-grep-guard.sh` had the
write guard's two patterns, a pass-through when `jq` is missing and a long jq program passed as an
argument. The final review of #736 checked both, and neither is the write guard's defect:

- **The program is 14 KB**, far under Linux's 128 KB limit on one argument; the write guard's program
  was 103 KB.
- **The pass-through when `jq` is missing is deliberate** and stated in the guard's own comment ("only
  a missing jq, which every hook here needs, passes everything"). The guard bounds a `git grep`, a
  read, so passing it lets through a slow search, not a write as the player.

What does fail open there is already queued: the guard's deny message is built with `jq -n --arg`,
and a reason quoting about 32,000 four-byte characters passes 128 KB, so `jq` fails and the hook
lets the command through — [sandy-plover](../todo/2026-09-26-sandy-plover/README.md), the git-grep
guard's deny message fits in one argument on Linux. The write guard's own fix for the same failure,
the reason on stdin and a fixed deny when `jq` cannot print, is in the
[dappled-owl record](2026-10-03-dappled-owl.md), "The guard fails closed", and is the pattern
sandy-plover can follow. The entry is closed with nothing built.
