## Fence image-diff error · 2026-09-09

PLAYTEST-50 clarified "hmm fence is invalid" as GitHub's "Error rendering embedded code / Invalid
image source" for the fence diff. The base file on main contains a forbidden double hyphen inside
an XML comment; `git show origin/main:assets/tiles/fence.svg | xmllint --noout -` reproduces its
parse failure. The branch replacement removes that invalid comment and passes XML validation;
Godot renders it successfully. The old side therefore remains invalid when a viewer compares
both revisions. The current rendered tile is preserved in
`evidence/svg-fence-preview-2026-09-09.png` for review independently of the image-diff viewer.
The player confirmed "the new file is valid" and "the diff viewer fails"; no further fence
asset change is needed for this report.
