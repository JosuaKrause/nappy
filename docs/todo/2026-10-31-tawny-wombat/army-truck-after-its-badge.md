# The army truck is placed for her when it comes, warned first

The player: "Army convoy should definitely placed for her not at dawn. Otherwise it might have driven
away by then" (minty-dolphin #852).

**Build:** the `military_convoy` row (the army truck, from day 13) is no longer planned at dawn. It
is placed for her while she walks, warned first by its screen-edge badge before it exists, the way
day 13's column on the main road is (`ResistanceHappenings`), so it cannot have driven away before
she gets there. Its badge then comes from the warning path alone.

*Proposed, not asked for:* the truck placed through the director's on-her-way placement
(`EventsAhead`), with the same fairness checks as any row placed after dawn.
