# Architecture

Version 1 to 2026-08-20. Status: proposal. Nothing is deployed; there is no Supabase project yet.

## 1. Summary

Supabase as the whole backend. Postgres with PostGIS, Auth, Storage, Realtime, Edge Functions,
and row-level security carrying the privacy requirements. A single web client, mobile-first,
installable, and usable offline for the parts that matter in a garden at 2am.

The shape of the system follows from one observation: **the protocol is the product, and the
software's job is to make the protocol easier to execute, not to replace it.** Every table below
corresponds to something the protocol tells a person to do on paper.

## 2. Guiding constraints

1. **It must work at 2am, one-handed, on a phone, outdoors, in the dark, possibly with no signal.**
   This is the actual operating environment. It drives offline-first, large tap targets, and a
   dark theme that does not destroy night vision.
2. **The user is distressed.** No feature may require exploration. Every screen states the next
   action.
3. **It must be free to run at small scale**, because charging distressed pet owners at the point
   of use is both distasteful and commercially hopeless, every meaningful competitor is free.
   This constrains inference cost hard, and is a large part of why camera triage runs on-device.
4. **It must degrade to paper.** Every feature has a printable equivalent, and the protocol
   documents stand alone. If the service is down, nobody's search stops.
5. **Location data is sensitive.** See section 6.

## 3. Why Supabase

Postgres is the right primitive here because the problem is genuinely relational and genuinely
geographic, and PostGIS means the search-grid and sighting-radius queries are ordinary SQL rather
than application code over a document store.

Beyond that, the pieces we need are ones Supabase already provides rather than ones we would
assemble: Auth including anonymous sessions, Storage for photos and camera clips, Realtime for
several people searching together, Edge Functions for the text-embedding work, `pgvector` for
sighting similarity, and RLS to express the privacy rules once, in the database, rather than in
every endpoint.

The free tier is sufficient for development and early real use.

**Rejected alternatives** and the reasoning: [`adr/0002-supabase-as-platform.md`](adr/0002-supabase-as-platform.md).

## 4. Components

```
┌──────────────────────────────────────────────────────────────┐
│  Web client (PWA, mobile-first, offline-capable)             │
│                                                              │
│  Search grid   Map      Sighting log   Camera review         │
│  Flyer/print   Protocol (bundled, works offline)             │
│                                                              │
│  ┌────────────────────────────────────────────────────┐      │
│  │ On-device camera triage (see docs/ai-scope.md)     │      │
│  │ Clips are classified locally. Video is not         │      │
│  │ uploaded unless the owner chooses to keep a clip.  │      │
│  └────────────────────────────────────────────────────┘      │
└───────────────────────────┬──────────────────────────────────┘
                            │
┌───────────────────────────▼──────────────────────────────────┐
│  Supabase                                                    │
│                                                              │
│  Auth ── anonymous sessions; no account to start a search    │
│  Postgres + PostGIS ── cases, grid, sightings, stations      │
│  RLS ── public vs owner views; location fuzzing              │
│  Storage ── reference photos, kept clips                     │
│  Realtime ── shared searching between helpers                │
│  Edge Functions ── gte-small sighting embeddings, notify     │
│  pgvector ── sighting similarity and de-duplication          │
└──────────────────────────────────────────────────────────────┘
```

## 5. Data model

First cut in [`../supabase/migrations/`](../supabase/migrations/).

| Table | Holds | Protocol step |
|---|---|---|
| `cases` | One lost cat. Escape point, escape time, status. | The whole thing |
| `pets` | Description, markings, reference photos. | Flyer, camera triage |
| `search_places` | An individual hiding place: deck, shed, culvert. | [search-grid](protocol/search-grid.md) |
| `search_visits` | One visit to one place: when, day/night, outcome. | [search-grid](protocol/search-grid.md) |
| `properties` | A canvassed address: contacted, access granted, blocked. | [neighbor-canvass](protocol/neighbor-canvass.md) |
| `sightings` | A reported sighting: where, when, confidence, source. | Throughout |
| `stations` | A feeding station and its camera. | [feeding-station](protocol/feeding-station-and-camera.md) |
| `station_events` | A confirmed camera event the owner kept. | [feeding-station](protocol/feeding-station-and-camera.md) |
| `helpers` | Someone searching with the owner. | Throughout |

Two design notes worth stating explicitly:

**`search_places` and `search_visits` are separate.** A place is not searched once; it is searched
repeatedly, at different hours, with different results. The protocol is emphatic that a daytime
search and a 2am search of the same shed are two different searches, and the schema has to hold
that or the feature lies to the user.

**`properties.access_state` is first-class.** `blocked`, a locked shed, nobody home, is the
highest-value queue in the system, because 11% of found cats were inside somebody else's building.
The app's job is to keep that list in front of the owner until each line is resolved.

## 6. Privacy

A lost-pet application publishes a map of where somebody lives, at a moment when they are
distressed enough not to think about it. This is treated as a first-class requirement rather than
a compliance afterthought.

Full decision: [`adr/0004-privacy-and-location-handling.md`](adr/0004-privacy-and-location-handling.md).

The rules the schema and RLS have to enforce:

1. **The escape point is never public at full precision.** Public views get a fuzzed centroid.
   Exact coordinates are visible to the owner and to helpers they have explicitly invited.
2. **Reporter contact details are PII** and are visible only to the case owner.
3. **Camera clips are not uploaded by default.** Triage happens on-device; only clips the owner
   chooses to keep are stored. These frequently contain a neighbour's property and passers-by.
4. **A case has an end.** Cases are closed and their location data purged on a schedule. An
   abandoned lost-pet listing is a permanent public record of somebody's address.
5. **Anonymous sessions are supported** so that starting a search does not require handing over an
   email address first.

## 7. Client

A PWA rather than native apps, and the reasoning is mostly about reach at the moment of need: the
person who needs this has never heard of it and is not going to install an app from a store at
11pm. A link that works immediately, and can be added to the home screen if the search goes on,
is a better fit.

Offline matters. The protocol documents, the grid, and the map tiles for the immediate radius are
cached; grid entries and sightings are captured offline and sync when signal returns.

Dark theme by default, this is used outdoors at night, and a bright screen costs the user the
dark-adaptation they need for the torch work.

## 8. Out of scope for v1

- Shelter data ingestion of any kind. See [`adr/0001`](adr/0001-cats-first-not-an-aggregator.md).
- Social auto-posting. The Facebook Groups API was removed in April 2024, which closes the surface
  that would have mattered most, for both reading and posting. Assisted posting, generate the
  content, hand the user a one-tap path into each app, is the version that can actually ship.
- Native mobile apps.
- Dogs, and cats with regular outdoor access. Different behaviour, different evidence, different
  protocol.
- Any payment path.

## 9. Open questions

- Front-end framework. Unchosen, and deliberately so until there is a contributor with a
  preference and the willingness to maintain it.
- Map tiles. Needs a provider whose licence permits offline caching and free use at this scale.
- Whether `station_events` should hold anything at all when triage is on-device, or whether the
  camera feature is entirely client-side with only owner-confirmed events reaching the server.
  Leaning toward the latter.
- Whether helper access needs accounts, or whether a signed link is sufficient and less friction.

## Provenance

Written by an AI agent on 2026-08-20 against the project's evidence base, market research and
technical research. No Supabase project exists and none of this has been built or validated. No
person has confirmed this document.
