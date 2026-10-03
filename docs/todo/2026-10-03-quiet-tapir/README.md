priority: next

# quiet-tapir — Guard remaining dynamic command writes · filed 2026-10-03
# Guard remaining dynamic command writes

[cozy-alpaca](../../playtests/2026-10-03-cozy-alpaca.md) records the #453 review's
explicitly separate findings: Python f-string shell commands fuse `f` with `git` in
tokenization; `$(which git) push origin v1` hides the executable; Python stdin loops
can supply an unreadable push refspec while only prompting. The source review says
these also occur on the base. Preserve the identity guard's fail-closed publishing
policy without executing candidate commands; submit reproductions only as hook JSON.

**Proposed, not asked for:** the `next` band and a focused parser extension using
the git-grep guard's f-string handling where appropriate. Establish regression and
false-positive cases before choosing the implementation; do not attempt a general
shell interpreter or expand ordinary write permissions.
