# Roadmap

Version 1 — 2026-08-20.

Ordered by how much each step reduces time-to-find, not by how interesting it is to build. The
protocol is already the most valuable thing here, so most of phase 0 is about making sure people
can actually reach it.

## Phase 0 — the protocol stands alone (mostly done)

The protocol works on paper, offline, with no account. This is the part most likely to matter to
somebody before any code ships.

- [x] Evidence base with sourcing and honest caveats
- [x] First 24 hours
- [x] Search grid, neighbour canvass, feeding station, approach, trapping
- [ ] **Review by someone who does this work.** Shelter staff, TNR trappers, MAR-trained
      searchers. This is the highest-value open item in the repository.
- [ ] A one-page printable version — the thing you hand somebody at a shelter counter
- [ ] Spanish translation. California, and the people most likely to be handed a printed sheet.

## Phase 1 — the search grid, and nothing else

The smallest thing that beats a notebook. If this does not beat a notebook, the central assumption
of the project is wrong and we should find that out cheaply.

- [ ] Supabase project, schema applied, RLS reviewed adversarially
- [ ] Create a case: pet details, escape point, escape time
- [ ] Map with the evidence rings drawn on it — 39 m, 137 m, 500 m, labelled with the real
      percentages
- [ ] Add places, record visits, `searched` / `partial` / `blocked`
- [ ] The blocked queue, front and centre
- [ ] Works offline; syncs later
- [ ] Printable grid sheet

**Success test:** one real owner uses it through a real search and says it helped more than paper
would have. Not downloads.

## Phase 2 — helpers and sightings

- [ ] Invite a helper by link, no account required
- [ ] Realtime shared grid — two people searching without re-searching each other's ground
- [ ] Public case page with **fuzzed** location (ADR 0004)
- [ ] Sighting reports from the public
- [ ] Sighting triage: structure, map, de-duplicate, rank (`gte-small` + `pgvector`)
- [ ] Re-search prompt when a sighting lands near searched ground

## Phase 3 — camera triage

Not before phase 1 proves the core, and not before the evaluation set exists.

- [ ] **Collect and label real night IR trail-camera clips.** Blocking. Everything in
      [`ai-scope.md`](ai-scope.md) section 2 is unevaluated without this.
- [ ] Evaluate candidate models against it — NVIDIA build's free tier is a good way to do this
      comparison without infrastructure
- [ ] On-device cat detection
- [ ] Identity ranking against reference photos, never asserting identity
- [ ] Keep-clip flow: only owner-confirmed clips reach storage

## Phase 4 — reach

The best protocol nobody finds is worth nothing.

- [ ] Flyer and sign generation, print-ready, from a template
- [ ] Assisted posting — generate per-platform content, one tap into each app. Not auto-posting;
      the Facebook Groups API closed in April 2024
- [ ] Shelter and rescue outreach: offer the printable protocol as something to hand out
- [ ] SEO on the protocol pages. This is how a frightened person at 11pm finds any of it

## Explicitly not planned

Reasoning in [`adr/0001`](adr/0001-cats-first-not-an-aggregator.md) and
[`adr/0003`](adr/0003-where-ai-earns-its-place.md):

- Shelter data ingestion
- Photo matching against listings databases
- Social auto-posting
- A chatbot
- Dogs, or cats with regular outdoor access
- Any payment path

## How to help

The most valuable contributions, in order:

1. **Correct the protocol** if you do this work and something is wrong.
2. **Real night IR trail-camera footage**, labelled. Phase 3 cannot start without it.
3. **Translation**, Spanish first.
4. Then code.
