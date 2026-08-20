# ADR 0004 — Location fuzzing, on-device video, and case expiry

Date: 2026-08-20. Status: accepted.

## Decision

1. **Public views never show the escape point at full precision.** They get a fuzzed centroid.
   Exact coordinates are visible only to the case owner and to helpers explicitly invited.
2. **Camera clips are processed on-device and are not uploaded by default.** Only clips the owner
   chooses to keep are stored.
3. **Sighting reporters' contact details are visible only to the case owner.**
4. **Cases expire.** Closed and stale cases have their location data purged on a schedule.
5. **Anonymous sessions are supported.** Starting a search must not require an email address.

## Context

A lost-pet application asks a distressed person to publish a map of where they live, at the exact
moment they are least likely to think about the consequences. That is worth designing around
rather than treating as the user's problem.

Three specific exposures:

**The escape point is the home address.** Not approximately — the protocol asks for the actual
door the cat went out of. A public case page with a precise pin is a published home address,
attached to a photo of the property's contents, plus a reliable signal that the occupant is
outdoors alone at 2am. We are not publishing that.

**Camera footage covers other people's property.** A feeding station camera aimed at a garden
captures the neighbour's fence line, the pavement, and passers-by, none of whom agreed to
anything. Uploading that stream to a third party is a much weaker position than processing it on
the owner's device, and it is the difference between a defensible answer and an awkward one when a
neighbour asks what the camera does. This reinforces a decision already taken on cost grounds in
ADR 0003.

**Abandoned listings become permanent records.** Lost-pet listings are rarely closed — the cat
comes home, or it does not, and either way nobody logs in again. Without expiry, the default
outcome is a permanent public record of somebody's home address and daily pattern, indexed by
search engines, attached to a sad story. Expiry has to be automatic, because relying on users to
tidy up is relying on the thing that never happens.

## Consequences

**Good.** The rules are expressible in row-level security, which means they are enforced in one
place and a contributor cannot leak an address by forgetting a filter in a new endpoint. On-device
video processing is simultaneously cheaper, more private, and works offline. Anonymous sessions
remove friction at the worst possible moment to ask for a signup.

**Bad.** Fuzzed public locations make the public sighting map less immediately useful — a helper
sees a circle rather than a pin. This is the correct trade and it will occasionally be annoying.
On-device processing means the server cannot help debug a triage failure it never saw. Expiry will
eventually delete a case somebody still cared about, so warnings before purge are required and the
window should be generous.

**Accepted risk.** Fuzzing radius, expiry window, and warning schedule are all unset and need
deciding before any public deployment. RLS policies in the initial migration are a sketch and have
not been reviewed adversarially — they must be before the repository goes public with a live
instance behind it.

## Options rejected

**Precise public pins, with a warning.** Rejected: a warning shown to someone whose cat went
missing an hour ago is not consent in any meaningful sense.

**No public case pages at all.** Rejected: neighbours reporting sightings is one of the strongest
recovery signals in the evidence base. The answer is fuzzing, not removal.

**Server-side video processing with a retention policy.** Rejected: a retention policy is a promise,
and not uploading the footage at all is a property. Where a property is available at similar cost,
take the property.

**Requiring accounts.** Rejected: friction at the exact moment the protocol says to move fast. The
first hour matters more than our user table does.
