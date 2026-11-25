priority: next

# curly-finch — The run's rows handed from main, so the catalogue keeps no run state · filed 2026-11-25

Filed from the review of lilac-marten's charger timing (pull request 1762). That change builds every
charger row from the run's `ChargerTiming` and keeps that timing in a static of the catalogue,
`EventCatalogue._chargers`, written once at boot by `main.configure()`. A component is handed
what it depends on and never fetches it from a static (**designing-classes**), so that static stands
as the one declared exception to the layer map (`tools/layer_map.py`'s `EXCEPTIONS`) until this
entry removes it. No words of the player's ask for this entry. It carries out the player's rule on
dependency injection (minty-lemur #794) and their rule that a legacy implementation never holds back
a clean design (minty-dolphin #852).

**Proposed, not asked for:** the whole entry and its band `next` are the orchestrator's proposal.
The plainer alternative is to keep the exception as it stands.

The item is [hand-the-runs-rows.md](hand-the-runs-rows.md).
