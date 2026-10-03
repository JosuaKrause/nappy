**The asking switch's reason says what is true** ([busy-ibis](../../playtests/2026-10-03-busy-ibis.md),
statement 8: "env was chosen because it's set by the session and not directly. but even with tricks
like updating the settings all it will do is prompt the command to me anyway").

The guard's comment on `NAPPY_ASK_FOR_PLAYER_WRITES` and the frosty-pelican record's "The player
can switch it off" paragraph say the switch is an environment variable because "a command an agent
runs cannot change the environment this hook is started in", unlike "a file it can write". An agent
can still turn it on with an ordinary file write — the `env` key of `.claude/settings.local.json`,
or making a machine with identities look like one without (`NAPPY_AGENTS_DIR`, or moving
`~/.config/nappy-agents`).

The switch stays an environment variable. Both places say instead that the session sets it rather
than a command, and that switched on any other way it only puts the command in front of the player
as a prompt; and that a session leaving it alone is **committing**'s rule, not something the hook
enforces. No code change.
