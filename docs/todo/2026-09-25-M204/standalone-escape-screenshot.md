**The standalone screenshot path combining `--start-escape` with `--walk` or `--after` is
investigated.** A report found it misbehaving; recipe capture advances and freezes on its own
simulation clock, so the working trailer recipes do not close this separate path. Reproduce it with
`tools/shot.sh --start-escape` and either flag, say what goes wrong and fix it or record why not.
