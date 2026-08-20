# ADR 0003: Two AI features; the rest rejected

Date: 2026-08-20. Status: accepted.

## Decision

We build **camera triage** and **sighting-report triage**, and nothing else. We do not build
general lost-pet photo matching, a conversational assistant, AI-generated flyer copy, or a
predictive location model.

Camera triage runs **on the owner's device**, not through a hosted inference API.

Full reasoning and provider assessment: [`../ai-scope.md`](../ai-scope.md).

## Context

The brief was explicit that AI should not be included for its own sake, and that the goal is
finding cats faster. That gives a usable test:

> Does this reduce the time between the cat being findable and the owner finding it?

Applied honestly, that test rejects most of what would otherwise go into a project like this.

**Camera triage passes clearly.** A feeding station with a trail camera produces several hundred
motion events a night, nearly all raccoons, opossums, other cats and moving branches. Owners
review that for two mornings and then stop, at which point the most reliable detection method in
the protocol quietly stops working. Cutting an hour of review to a minute keeps the station
running for the weeks it may need to. That is a direct reduction in time-to-find.

It also passes on tractability, and for a structural reason. General lost-pet matching is
open-set 1:N identification against a national database, where published benchmarks converge near
68% true acceptance at strict false-acceptance rates. Camera triage asks a much easier question
(does this clip contain a cat, and is it plausibly yours) over tens of candidates from one
location against many reference photos. The first stage is ordinary object detection and delivers
most of the value on its own.

The failure modes differ just as sharply. A false positive in camera triage costs the owner
twenty seconds looking at a raccoon. A false positive in identity matching is an identity claim
made to a grieving owner. We are only willing to ship the first kind.

**Sighting triage passes on smaller but real grounds**, and it is the one place Supabase's own AI
fits: `gte-small` runs natively in Edge Functions with no external call, and `pgvector` stores the
result.

## On-device rather than hosted

Three reasons, in order of weight.

**Privacy.** Trail cameras aimed at a feeding station capture the neighbour's garden, the
pavement, and people who have not consented to anything. Processing that on the owner's own device
is a materially better posture than uploading it to a third-party inference endpoint, and it is
the difference between a defensible answer and an awkward one when a neighbour asks.

**Cost.** Several hundred clips a night per active search, for a product that must be free at the
point of use, is precisely the workload that breaks per-inference pricing.

**Offline.** Checking the camera in a garden with poor signal is a normal case, not an edge case.

## On NVIDIA's free tier

The free tier at build.nvidia.com is real, roughly 1,000 credits, no credit card, 40 requests per
minute, 100+ models behind OpenAI-compatible endpoints, and public sources state plainly that it
is unsuitable for real user traffic.

**We use it for evaluation, not serving.** It is a genuinely good way to compare vision-language
models against a sample of real night IR clips without standing up GPU infrastructure, and that
evaluation is worth doing early. At 40 RPM it cannot serve the workload, and building on it would
mean rebuilding later.

These figures come from third-party summaries, not NVIDIA's own pricing page, and no account
exists. Verify before relying on them.

## Consequences

**Good.** Small, defensible AI surface. No inference bill on the critical path. No dependency on a
provider's free tier. The features that ship are the ones that would survive someone asking what
they are for.

**Bad.** On-device processing constrains model size and adds client complexity, model download,
storage, and a real difference between a recent phone and an old one. Rejecting general matching
means an owner whose cat did reach a shelter is not served by us; the protocol sends them to Petco
Love Lost, which does it better.

**Accepted risk.** None of the camera triage claims have been evaluated. We have no labelled
sample of real night IR trail-camera footage, and academic benchmarks on curated datasets are poor
evidence for it. Building that sample is the first task before any of this is committed to.

## Options rejected

Each of these was considered and rejected on the test above; reasoning in
[`../ai-scope.md`](../ai-scope.md) section 5.

- **General lost-pet photo matching.** Under 2% of found cats were in a shelter, the data is not
  obtainable, and Petco Love Lost already does it free and nationally.
- **A conversational assistant.** The owner at 11pm needs a checklist and a map. The correct answer
  is already written down and does not vary. Chat would add latency, non-determinism and cost while
  helping nobody.
- **AI-generated flyer copy.** A template produces better flyers, the constraints are fixed and
  known, and it works offline, costs nothing, and cannot produce something strange on the worst
  night of somebody's year.
- **A predictive heat map of where the cat is.** The distance distributions are population
  statistics, not a per-cat prior. Rendering them as a heat map would manufacture false confidence
  about specific properties. The honest version is a circle on a map with the real percentages
  written next to it.
