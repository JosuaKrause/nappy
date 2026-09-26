**`test_finale.gd` leaves `GameState.escape_section` set.** Run in one process just before
`test_resistance.gd`, a finale test leaves the section at `BUILDING`, so the next `City`'s
`Blackout` starts dark at `setup()` (`_in_the_escape()` reads that flag) and
`_test_the_sabotage_silences_the_city` fails three checks; every suite is green alone and CI's
shards keep them apart. Found building M192
