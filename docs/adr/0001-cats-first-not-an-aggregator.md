# ADR 0001: Indoor cats only, and not a shelter-data aggregator

Date: 2026-08-20. Status: accepted.

## Decision

This project targets **escaped indoor-only cats** and does not aggregate shelter data.

The originating idea was a California-wide lost-pet aggregator: ingest every shelter, animal
control and social source; match photos with AI; generate and auto-post flyers. We are building
none of that.

## Context

Market and technical research on the original concept returned three findings that between them
remove the premise.

**The concept already exists, at national scale, for free.** Petco Love Lost, a nonprofit,
built on facial-recognition technology from Finding Rover, draws on intake photos from roughly
3,000 shelters plus Nextdoor and Ring listings, does automatic photo matching, and generates
flyers. It reported its 100,000th confirmed reunion in 2025.

**California is where the incumbent is strongest, not weakest.** The original strategy assumed
thin coverage in California. It is the opposite: LA Animal Services participates in the LA Lost
Pet Coalition, a joint effort with Petco Love and around 20 LA-area shelters to make Petco Love
Lost the region's primary reporting tool. LA County DACC is a named partner. Riverside County
uploads good-samaritan intakes automatically. San Bernardino, Moreno Valley, Monterey, Pasadena
Humane and San Diego Humane all route owners to it. A challenger would be asking shelters to feed
a second database while their own guidance points owners at the first.

**The data is not obtainable anyway.** There is no open, statewide, real-time stray feed.
Published government open data is retrospective statistics without photos, useful for oversight,
useless for matching. Live listings sit behind vendor portals, principally 24PetConnect; its
successor platform's stated API intent is integration with trusted industry partners, which reads
as a partner programme rather than an open surface. Scraping is the obvious path and is exactly
the access that closes once noticed.

Then the finding that decided it. In the Huang et al. 2018 study of 1,210 missing cats, **under
2% of found cats were found in a shelter.** 83% were found outside; 11% inside a neighbour's
building.

So shelter ingestion is simultaneously the hardest part of the build, the most legally exposed,
the most dependent on partnerships we cannot obtain, in direct competition with a free
better-connected incumbent, and aimed at under 2% of where cats are actually found.

## Why indoor cats specifically

Cats return to owners at roughly 3% from shelters against roughly 40% for dogs. That gap is the
largest unaddressed failure in the category, and it is not a matching-technology gap. Indoor-only
cats are found at a median of 39 m from the escape point, hiding and silent. The advice owners
receive is built around dogs, range widely, respond to calling, get picked up and taken to a
shelter, and following it sends the owner to the wrong place, doing the wrong thing, during the
week that matters most.

Cats are also where the incumbent's general-purpose tool is weakest, which makes it a defensible
position rather than a worse copy of something free.

## Consequences

**Good.** The expensive, gated, legally fraught part of the build disappears. The remaining work,
a protocol and a coordination tool, needs no partnerships and no vendor permission. The
protocol is useful on paper immediately. Petco Love Lost becomes a thing we send owners to rather
than compete with, which is a much better position.

**Bad.** No listings database means no network effect and no defensibility through data. The
addressable problem is much smaller. We are betting that better instructions beat a bigger
database, and that bet is untested.

**Accepted risk.** The central assumption, that software materially improves on the paper
protocol, is unvalidated. If it turns out to be false, the correct outcome is that the protocol
documents get distributed as widely as possible and the app is abandoned. That is a good outcome
and the repository is structured so that it remains available.

## Options rejected

**Build the aggregator as originally framed.** Rejected: competes head-on with a free,
better-connected, nonprofit-funded incumbent that California shelters actively promote. The likely
outcome is a technically competent product nobody checks.

**Aggregate only the sources the incumbent misses**. Facebook groups and the long tail of small
rescues. Rejected: Facebook is the largest such gap and Meta removed the Groups API in April
2024, closing it for both reading and posting. The gap exists because it is closed, not because it
was overlooked.

**Cats generally, indoor and outdoor.** Rejected for v1: outdoor-access cats range much further
(median 300 m against 39 m) and a missing outdoor cat more often means something happened to it
than that it is hiding nearby. Different behaviour, different protocol, weaker evidence. This can
be revisited once the indoor case works.
