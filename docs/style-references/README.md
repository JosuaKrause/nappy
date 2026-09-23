# Style references

**Approved art style references, and nothing else.** This folder is flat — files directly here,
no subfolders — so a name is the only lookup a search needs. What each file is a reference *for*:

| File | Family | Role | What it supplies |
| --- | --- | --- | --- |
| `graphics-reference-urban-01.jpeg` | City/environment | Style | The diagonal illustrated urban style: fine ink linework and material detail for streets, vehicles, shops and crowds. |
| `graphics-reference-urban-02.jpeg` | City/environment | Style | A second illustrated urban view, for the same street/vehicle/shop/crowd detail the first alone does not cover. |
| `graphics-reference-cardinal.jpeg` | Player/gameplay | Style | The style-transferred gameplay reference — the floor for the available cardinal perspective, not the illustrated style or detail target on its own. |
| `graphics-reference-mother.jpeg` | Player (mother) | Identity + style | The mother, her clothing, face, pram and baby: brown hair in a high bun, green coat, and the broader illustrated-city style read together with the urban pair. |
| `posters-01.jpg` | Posters (`art/events/posters/`) | Style + content | The player's generated reference sheet for M180's posters — the leader, rules, curfew, uniform and wanted notices, some kinds repeated. |

`docs/VISUALS.md`, "Reference roles" says how illustrated-png generation actually uses these; this
file only says which picture is for what.

## Adding one

Run `tools/reference.sh --style <file>`. It shrinks and strips the source exactly as an ordinary
reference does — see `.claude/skills/reference-photos/SKILL.md` — and drops the result flat into
this folder rather than into `docs/reference/`. Rename it by subject as that skill describes, add
its row to the table above, and say what family and role it serves before citing it from a
generation record.

The source has to be a file on disk: a picture pasted into the prompt from a clipboard has no path
behind it and cannot be handed to the script, even though the session can see it. Ask where it is
saved, or have it dragged in from Finder or the Downloads folder, before running the command above
— see the reference-photos skill, "The script needs a file on disk, not a picture in the
conversation".

Raw evidence, review sheets, run captures and generation records stay in `docs/evidence/`; only an
approved style reference belongs here.
