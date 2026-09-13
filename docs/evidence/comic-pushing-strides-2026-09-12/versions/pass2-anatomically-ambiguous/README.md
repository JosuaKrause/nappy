# Pass2 anatomical comparison

This fixed comparison uses all ten A/B figures from `raw/p2-acb-pass2.png` and all five C figures
from `raw/p2-c-row.png`. Human review found that side B and northeast B varied the leg silhouette
without clearly exchanging the complete anatomical legs from hip to shoe. The final registered
family replaces those two whole B figures with pass4.

The exact comparison is reproducible with:

```sh
UV_CACHE_DIR=/tmp/nappy-uv-cache uv run --frozen python \
  docs/evidence/comic-pushing-strides-2026-09-12/convert.py register \
  --selection pass2 --output-dir /tmp/p2-pass2-registration
```

Its `manifest.json` names every selected whole figure, freezes the input-manifest hash and records
the hashes of all extracted images, registered sprites and review outputs.
