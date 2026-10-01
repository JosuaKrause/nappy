priority: now

# breezy-tapir — Keep tests out of the web download · filed 2026-09-30
# Context

The player asks to inspect the downloaded package and calls test-file exclusion "an easy win".
See [cozy-walrus, exclude tests from the downloaded game](../../playtests/2026-09-30-cozy-walrus.md).
The live package contains test suites and probes. Keep those available for development and CI
while excluding them from the Web download. The `now` band is the filer's proposal for this
bounded loading improvement alongside the separate scenery investigation.
