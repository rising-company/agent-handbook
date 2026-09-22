# ADR-0013 — Every product ships a link preview card

**Status:** Accepted

## Context

Rising products travel by link. A tool whose whole state is in the URL (`true-cost-to-phone`), a shared huddle, a venue map sent to a client — the link *is* the distribution, and the preview card a scraper renders is the first impression far more often than the home page is.

Until now nothing said what that card had to be. The outcomes were the two bad ones:

- **No tags at all** — Slack, iMessage and X render a bare rectangle with a URL under it. The share carries nothing.
- **A wordmark on a colored field** — technically a card, but it tells a reader nothing the domain didn't already say, so the click is curiosity rather than verification.

`true-cost-to-phone` solved this properly in September 2026 (commit `c9dda15`): its card is a picture of the page's own carrier chart — same segments, same colors, same cheapest-first ranking — so the argument survives a timeline. Building it surfaced two failure modes that are invisible until they have already cost you weeks of shares:

- **Scrapers cache `og:image` by URL.** A regenerated card behind an unchanged URL keeps serving last month's numbers to Facebook, Slack and X for days.
- **A card built from product data goes stale the moment the data moves**, and nothing in a browser or a build notices.

## Decision

- **Every Rising Company product ships a link preview card.** It is a per-product obligation with the same standing as the rising.company backlink (ADR-0005), not an optional polish item.
- **The card makes the product's argument out of the product's own data** — the chart, the grid, the ranking the page itself computes. A logo on a rectangle does not satisfy this. If the product has a number, the number is on the card.
- **The spec is the design system's**, as with every other shared visual decision: "Link Preview Card (required branding)" in <https://design-system.rising.company/llms.txt>. Worked template: `patterns/og-card.html`. In summary — 1200 × 630 CSS px, **Daylight always** (a stranger sees it first), six parts (edge rule → eyebrow → headline → lede → **evidence band** → footer stamp), shot at 2× to a 2400 × 1260 PNG after `document.fonts.ready`.
- **The card is a generated artifact, not a drawing.** The renderer is committed next to it (`tools/og.html`) so the card can be rebuilt from the data rather than redrawn. Next.js products use `src/app/opengraph-image.tsx` with `ImageResponse` at 1200 × 630.
- **`og:image` carries a `?v=YYYY-MM-DD` stamp**, bumped in the same commit that replaces the PNG. Next.js content-hashes the URL and needs no stamp.
- **Where the card is built from product data, a test pins it** (ADR-0006): the numbers printed on the committed PNG against what the data now produces, and the stamp against the data's own timestamp. Reference implementation: `true-cost-to-phone/tests/og.test.mjs`.
- The full tag list is in the design system spec and enforced by the [new project checklist](../checklists/new-project-checklist.md#branding--metadata).

## Consequences

- New projects get this from the checklist. **Existing products need a retrofit** — `os`, `huddle`, `venue-map`, `safe` and `fc_tank` each need a card built from their own object, which is a design task per product, not a copy-paste.
- Regenerating the card becomes part of any change that moves the numbers it prints. For data-driven products the test makes that non-optional; for the rest it is a review habit.
- The design system carries the reference implementation and follows the rule itself (`tools/og.html` → `og.png`), so "what should this look like" has an answer that is always current.
- Cards are committed PNGs, roughly 100–150 KB each. That is deliberate: a static file served from the product's own domain has no cold-start and no runtime dependency at the moment a scraper asks for it.
