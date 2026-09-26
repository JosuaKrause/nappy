## M67 — The page is a thing people share · built 2026-09-02

*(2026-09-02: "use the pram logo for social media for the nappy.josuakrause.com page, too", "add
other social media info in the html head", and "the asset license is just an md file with custom
text — should we get a proper named license for the assets?")*

**The card image had to be published, not merely pointed at.** The Web export packs everything under
`assets/` into the `.pck`, and the deploy workflow uploads only `build/web`, so an `og:image`
pointing into `assets/` would have unfurled as a blank card while being perfectly correct markup.
`deploy.yml` copies the logo to `build/web/social-card.png` after the export, which is the path the
tag promises. **`assets/logo.png` over `assets/icon_stroller_1280x640.png`**, both being 1280×640:
the logo is already the game's public face on the README, so the shared link and the repo's front
door show one image rather than two, and it carries the wordmark for a client that renders only the
picture.

**Every attribute is single-quoted**, because `html/head_include` is one long double-quoted `.cfg`
value and a literal `"` inside it ends the string early — a failure that would have looked like a
broken export rather than like a quoting bug.

**The asset licence is CC BY-NC-ND 4.0, and the badge still will not say so.** The full legal text
ships in `LICENSE-ASSETS.md` with the project's own paragraph about which paths each licence
covers, which no licence supplies. **It is one deliberate loosening**: CC BY-NC-ND permits verbatim
sharing with credit, which "all rights reserved" did not; selling and altered versions stay
forbidden. What was asked for and did not arrive is the name on GitHub — its detector matches
against the choosealicense.com corpus, which carries CC BY 4.0, CC BY-SA 4.0 and CC0 and
deliberately excludes every NonCommercial and NoDerivatives variant, so **no filename makes it show
as a name.** *Open to overturn: the only way to a second named badge is a licence in that corpus,
which means giving up either the non-commercial or the no-derivatives half.*
