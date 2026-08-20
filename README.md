# Kitty Come Home

A search tool for indoor-only cats that got out.

Not an aggregator. Not a listings site. The premise is narrower and, I think, more useful:
**most lost-pet advice is built around dogs, and for an escaped indoor cat that advice sends
the owner in exactly the wrong direction**, driving the neighbourhood, calling shelters,
posting online, while the cat is lying still under a deck four houses away, quite possibly
hearing all of it and staying put.

This project's job is to get the owner searching the right ground, in the right way, in the
first 24 hours.

## Why this specifically

From a 2018 study of 1,210 missing cats (Huang et al., *Animals*) and the Missing Animal
Response case data that preceded it:

| Finding | Figure |
|---|---|
| Indoor-only cats: distance from escape point when found | **median 39 m** (IQR 9 to 137 m) |
| All cats found within 500 m of escape point | 75% |
| Found cats that were in a shelter | **under 2%** |
| Found outside / in a neighbour's house | 83% / 11% |
| Recovered alive by day 7 | 34% (95% CI 31 to 37%) |
| Recovered alive within one year | 61% (95% CI 57 to 64%) |
| Microchipping's effect on recovery | none detected (p = 0.331) |

Two of those numbers set the whole design.

**Under 2% were in a shelter.** Every hard part of a conventional lost-pet product, ingesting
shelter feeds, negotiating vendor API access, matching photos against intake listings, is aimed
at under 2% of where cats are actually found. It is the most expensive, most legally fraught,
most partnership-gated part of the build, and for this animal it is close to the least valuable.
We are not building it.

**Median 39 metres.** The cat is almost certainly within a few houses. The search that finds it
is a physical search of a small area, done slowly, at night, with a flashlight, in places a
frightened animal can wedge itself into. That is not a technology problem. It is a
"nobody told the owner, and the owner is panicking" problem.

So the product is the protocol first, and software second, software that supports the protocol
rather than replacing it.

Full sourcing and caveats: [`docs/evidence.md`](docs/evidence.md).

## What this is

1. **A field protocol**, in [`docs/protocol/`](docs/protocol/). What to do, in order, starting the
   minute you notice. Written for someone competent and frightened at 11pm. It works on paper,
   offline, with no account and no app. **This part is finished enough to use today.**
2. **A search coordination app**, a mapped search grid you can work through and share with
   whoever is helping, sighting reports from neighbours in one place, and a feeding-station log.
   Not built yet.
3. **Camera triage**, the one place AI clearly earns its keep here. See below.

## What this is not

- Not a competitor to Petco Love Lost. That is free, national, has facial matching, and most
  California shelters already point owners at it. Use it, the protocol tells you to, on day one.
  Duplicating it would produce a technically competent product nobody checks.
- Not a shelter-data aggregator. See the 2% figure above.
- Not a social auto-poster. Meta removed the Groups API in April 2024, which closes the surface
  that would have mattered most, for both reading and posting.

## Where AI earns its place

The test applied throughout: **does this reduce the time between the cat being findable and the
owner finding it?** If not, it does not go in, however good the demo looks.

**It earns its place in camera triage.** Put a camera on a feeding station and by morning you
have several hundred motion events, nearly all of them raccoons, opossums, next door's cat, and
a branch moving. Reviewing that is an hour the owner does not have before work. A classifier that
cuts it to "four clips contain a cat, here they are, this one is closest to your reference photos"
turns an unusable pile into a one-minute check.

This works where general lost-pet photo matching does not, and the difference is structural.
Matching a photo against a national listings database is open-set 1:N identification, the
published benchmarks converge near **68% true acceptance** at a strict false-acceptance rate,
because the found cat may simply not be your cat. Camera triage is a different question: a
handful of candidates, from one location, against a known reference set of your own cat, where
the honest answer "possibly, go look" is a completely acceptable output. A false positive costs
twenty seconds. Compare that to the failure mode of an identity claim made to a grieving owner.

**It probably earns its place in sighting triage.** Neighbours report in free text: "grey tabby,
by the blue house on Elm, around nine." Turning that into structured, mapped, de-duplicated,
plausibility-ranked records is real work that text embeddings do well.

**It does not earn a chatbot.** At 11pm the owner needs a checklist and a map, not a conversation.

Reasoning, provider assessment and rejected options: [`docs/ai-scope.md`](docs/ai-scope.md).

## The site

**[kittycomehome.opsvibe.systems](https://kittycomehome.opsvibe.systems)**

The protocol as a phone-first web page. No account, no analytics, no cookies, no third-party
requests of any kind. It caches itself so it works with no signal, it prints as a handout, and
it has a red-on-black night mode so reading it does not cost you the dark adaptation you need
for the torch work at 2am.

Source in [`site/`](site/). Deployment and the DNS record: [`docs/deployment.md`](docs/deployment.md).

## Status

| Part | State |
|---|---|
| Field protocol | Written, sourced, usable today |
| Public site | Built and tested, pending repo visibility and one DNS record |
| Supabase project | Live: schema applied, RLS verified 14/14, advisors clean |
| Public API surface | None, deliberately. See [ADR 0004](docs/adr/0004-privacy-and-location-handling.md) |
| Search coordination app | Not started |
| Camera triage | Not started, blocked on an evaluation dataset |

If you only read one thing here, read
[`docs/protocol/first-24-hours.md`](docs/protocol/first-24-hours.md).

## Stack

Static HTML on GitHub Pages for the site: no framework, no build step, no dependencies, so
there is nothing to rot underneath a page somebody may need on bad signal.

Supabase for the planned search tool. Postgres with PostGIS for the search grid and sighting
geography, Auth, Storage, Realtime for shared searching, Edge Functions, and row-level
security doing the privacy work. See [`docs/architecture.md`](docs/architecture.md).

## Contributing

Contributions are welcome, and corrections to the protocol are the most valuable kind. If you
do this work, shelter staff, trappers, MAR-trained searchers, or someone who has found their
own cat and learned something the hard way, and the protocol is wrong, please
[open an issue](https://github.com/TechLuddite/kitty-come-home/issues/new/choose). Say what happened. Evidence beats opinion here, but
field experience is evidence.

See [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Licence

Code: MIT. Documentation, including the protocol: CC BY 4.0, reuse it, translate it, print it,
hand it to someone at a shelter counter. See [`LICENSE`](LICENSE).

## A note on why

Cats get home at roughly a tenth the rate dogs do, and the gap is not because the technology is
missing. It is because the standard advice was written for an animal that behaves nothing like
a frightened indoor cat. That gap is closable with a checklist and a flashlight.

If this repository helps one person find one cat, it was worth writing.
