# Playtest 132 — The published page counts visits, and how far people get

2026-09-25. Said in conversation, after finding that the Google Analytics tag on the player's own
website sends nothing (its snippet pushes an array where gtag.js needs the `arguments` object).

## What was put to the player

Could the game's page count visitors the way the website does? A cookie-free counter was offered
(GoatCounter or Cloudflare Web Analytics); GoatCounter was recommended because it can also count
custom events without cookies, such as how far a run got.

## What the player said

> "https://www.josuakrause.com/ I think is using a way to count visitors a) can we use the same
> for https://nappy.josuakrause.com/ and b) does it actually work still?"

> "is there a cookie-free one?"

> "should I set up one goatcounter account for both nappy and my website or just one for each? do
> subdomains count?"

The player then sent the site's tag, one GoatCounter site for both:

> `<script data-goatcounter="https://josuakrause.goatcounter.com/count" async src="//gc.zgo.at/count.js"></script>`

> "and let's get info about how far people get, whether they start from a save, whether they
> restart, how they die, what tasks they did, etc. anything with debug doesn't get tracked"

## The statements

1. **The published page counts visits with GoatCounter**, on the site `josuakrause.goatcounter.com`
   the player's website shares; the game's hits carry its host so the two stay apart.
2. **The game counts how people play**, as anonymous events: how far a run gets, whether it starts
   from a save, whether they restart, how a day is lost, which tasks were done, "etc.".
3. **Anything with debug is not tracked**: a debug build, and a published page carrying `?debug=1`
   (M193), send nothing, the page load included.
