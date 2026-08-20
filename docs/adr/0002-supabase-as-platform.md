# ADR 0002: Supabase as the entire backend

Date: 2026-08-20. Status: accepted.

## Decision

Supabase provides the whole backend: Postgres with PostGIS, Auth, Storage, Realtime, Edge
Functions, `pgvector`, and row-level security. No separate vector database, no separate auth
provider, no separate object store.

## Context

The deployment target was specified as Supabase. This ADR records why it also happens to be the
right choice, and what we are giving up.

The data is genuinely relational, cases to places to visits, properties to contacts, sightings to
grid squares, and genuinely geographic. PostGIS makes "every place within 50 m of this sighting
that has not been searched since Tuesday" one query rather than an application-layer join over a
document store. That query is the search-grid feature.

RLS matters more than usual here. The privacy rules in ADR 0004, public sees a fuzzed location,
the owner sees exact coordinates, only the owner sees reporter contact details, are exactly what
row-level security expresses well, and expressing them once in the database rather than in every
endpoint is a meaningful reduction in the ways a contributor can accidentally leak somebody's home
address.

`pgvector` plus `gte-small` in Edge Functions covers the sighting-triage work described in
[`../ai-scope.md`](../ai-scope.md) with no external embedding API and no additional key to manage.

## Consequences

**Good.** One service, one dashboard, one set of credentials. A contributor can run the whole
stack locally with the Supabase CLI. The free tier covers development and early real use, which
matters for a product that must be free at the point of use. Migrations are plain SQL and review
well in a pull request.

**Bad.** Platform lock-in, mitigated by the fact that it is Postgres underneath, the schema and
data are portable even if Auth, Storage and Edge Functions are not. Edge Functions are Deno, which
is a constraint on contributors. Supabase's built-in AI inference is text-only, so it does nothing
for camera triage; that work lives on-device.

**Accepted risk.** Free-tier limits are not yet tested against real usage. Storage is the exposure
if camera clips ever get uploaded at volume, which is a further reason triage runs on-device and
only owner-confirmed clips are stored.

## Options rejected

**Firebase.** Rejected: the geographic and relational queries this project is built on are
awkward in Firestore, and PostGIS has no real equivalent there.

**Postgres on a VM, self-assembled.** Rejected: more control than this project needs, and every
hour spent on auth plumbing and backups is an hour not spent on the protocol. Revisit only if
Supabase's limits become binding.

**Supabase plus a dedicated vector database.** Rejected as premature. `pgvector` handles the
sighting volumes plausibly involved here by a wide margin. Adding a second datastore for a feature
that is not built yet would be speculative complexity.

**Cloudflare Workers with D1.** A reasonable alternative on edge performance and cost, rejected
because D1 has no PostGIS equivalent and the geographic queries are central rather than incidental.
