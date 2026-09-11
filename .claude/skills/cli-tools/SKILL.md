---
name: cli-tools
description: What every command-line entry point owes — help on --help and -h, rejection of anything it does not understand before any work starts, and one place the flag list lives. Load this BEFORE adding or changing anything under tools/, or the game's own dev flags.
---

# Command-line entry points

**Everything reachable from a shell prints help and refuses what it does not understand.** *(2026-09-11:
"help doesn't work it just starts the game which becomes unresponsive. also invalid arguments should
get rejected and cause the help to be printed"; "rejecting invalid args and having a --help/-h is a
general requirements for everything that is cli accessible".)* That is every script in `tools/`,
shell or Python, and the game's own dev-flag surface behind `tools/run.sh`, `tools/shot.sh` and the
web build's query string.

Three obligations, each checked before the tool does anything else:

- **`--help` and `-h` print the usage and exit 0.** The usage names every flag, what it takes, and
  one example. Nothing else happens on that path — no Godot launch, no export, no file written.
- **An unknown flag, a flag missing its value, or a stray word is rejected**: the usage on stderr,
  a non-zero exit, and again nothing else happens. A tool that forwards arguments to something
  else validates them first; forwarding is not a reason to accept anything.
- **The flag list lives in one place per tool.** A script that forwards dev flags to the game
  reads its list from where the game declares them, or the two drift within a milestone. `README.md`'s
  flag section is documentation of that list, not a second copy of it.

**Why it is a rule and not a nicety.** A tool that ignores what it does not know turns a typo into
the wrong run — a screenshot rig on the wrong day, a game launched when the player asked what the
flags were — and the failure is silent until somebody reads the log. On this project a windowed
launch also takes the player's own screen, so the wrong run costs more than a wasted second.

**A new tool ships with a test of both paths**: run it with `--help` and with a flag it does not
know, and assert that neither did the work. The Python tools have `tools/test_*.py` for this;
a shell tool gets the same two cases wherever its own test lives.
