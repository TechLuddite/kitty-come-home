# Where AI earns its place

Version 1 to 2026-08-20. Status: proposal. Nothing here has been built or evaluated.

## 1. Summary

I recommend we ship exactly two AI features, in this order:

1. **Camera triage**, reduce a night's several hundred motion clips to the few containing a cat,
   ranked against the owner's reference photos. This is the highest-value AI application in the
   project by a wide margin.
2. **Sighting-report triage**, turn free-text reports from neighbours into structured, mapped,
   de-duplicated, plausibility-ranked records.

And that we explicitly do not build general lost-pet photo matching against a listings database,
a conversational assistant, or AI-generated flyer copy. Reasoning in section 5.

The test applied throughout: **does this reduce the time between the cat being findable and the
owner finding it?** A feature that does not measurably do that is not worth the dependency, the
cost, or the failure modes, however good it demonstrates.

## 2. Camera triage: recommended

### The problem

A feeding station with a trail camera generates several hundred motion events overnight. Nearly
all are raccoons, opossums, neighbourhood cats, moths in the infrared beam, and moving branches.
The owner has to review them before work. In practice they review them for two mornings and then
stop, which is the point at which the most reliable detection method in the whole protocol
quietly stops working.

Cutting an hour of review to a minute keeps the station in service for the weeks it may need to
run. That is a direct, measurable reduction in time-to-find.

### Why this is tractable where general matching is not

This is the important distinction, and it is easy to lose.

General lost-pet photo matching is **open-set 1:N identification**: is this cat, from a national
database of 200,000 listings, your cat, when it may be no cat in the database at all. Published
work is better than it used to be; a 2026 dual-stream CLIP-ViT approach reports Rank-1 accuracy
around 0.974 on a 173-identity benchmark. But the same paper reports **open-set verification
converging near 68% true acceptance** at the strictest false-acceptance rate, and open-set is the
real deployment condition. The paper also identifies down-sampling and motion blur as the dominant
corruptions, which describes essentially every found-pet photo, and every night-time IR clip.

Camera triage is a materially easier problem on four counts:

| | General matching | Camera triage |
|---|---|---|
| Candidate pool | ~200,000 listings, nationwide | Tens of clips, one location |
| Question | "Which of these is your cat?" | "Does this clip contain a cat, and is it plausibly yours?" |
| Reference set | One or two listing photos | Many owner photos, multiple angles |
| Cost of a false positive | An identity claim to a grieving owner | 20 seconds looking at a raccoon |
| Cost of a false negative | The match is missed | Mitigated, all clips stay reviewable |

The first stage, **is there a cat in this frame at all**, is ordinary object detection and is
close to solved. That stage alone delivers most of the value, because it is what removes the
raccoons and the moving branches. Identity ranking is a second, softer stage on top.

### Design constraints

1. **Never assert identity.** Output is "cat detected, ranked by similarity to your reference
   photos," with the owner confirming. This is a product rule, not a threshold to tune.
2. **Never discard a clip.** Triage reorders; it does not delete. The owner can always see
   everything.
3. **Night IR footage is greyscale.** Colour is unavailable. Ranking must work on pattern,
   proportion and gait.
4. **Recall over precision.** Showing a raccoon costs 20 seconds. Hiding the cat costs a night.

### Recommended placement: on-device or self-hosted, not a hosted API

I recommend image processing run locally, on the owner's phone or machine, rather than by
uploading clips to a hosted inference API.

Three reasons, in order of weight:

1. **Privacy.** These are cameras pointed at residential property, frequently capturing a
   neighbour's garden, the pavement, and passers-by who have not consented to anything. Uploading
   that to a third-party inference endpoint is a materially worse posture than processing it on
   the owner's own device, and it is much harder to defend if anyone asks. See
   [`adr/0004-privacy-and-location-handling.md`](adr/0004-privacy-and-location-handling.md).
2. **Volume and cost.** Several hundred clips a night per active search, for a product intended to
   be free, is exactly the workload that makes hosted per-inference pricing untenable.
3. **It works offline.** The owner checking the camera in a garden with poor signal is a normal
   case.

A cat detector is small. This is well within what runs on a phone.

## 3. Sighting triage: recommended, second

Neighbours report in free text, by SMS, in a form, and verbally: "grey tabby, by the blue house on
Elm, around nine." Useful work exists in structuring that: extracting time and location, matching
against the search grid, de-duplicating the same cat reported by four people, and ranking by
plausibility against the known escape point and elapsed time.

**This is where Supabase's built-in AI actually fits**, and the fit is specific: Supabase Edge
Functions run the `gte-small` embedding model (384 dimensions) natively since Edge Runtime
v1.36.0, with no external API call, and `pgvector` stores and indexes the result. Supabase also
documents an automatic-embeddings pattern using triggers, `pgmq`, `pg_net` and `pg_cron`.

The constraint worth being clear about: **`gte-small` is a text model.** Supabase's built-in
inference does not do image embeddings. So Supabase AI serves sighting text well and does nothing
for camera triage, where Supabase's role is `pgvector` as storage for embeddings produced
elsewhere, not as the model.

## 4. Provider assessment

### NVIDIA build (build.nvidia.com): prototyping only

The free tier is real and useful, and it is not a production path.

What the public sources indicate as of August 2026: roughly 1,000 inference credits on joining
the free NVIDIA Developer Program, no credit card, a **40 requests-per-minute** rate limit with
an increase to 200 RPM available on request, 100+ hosted models behind OpenAI-compatible
endpoints. Multiple sources state plainly that the free tier is unsuitable for real user traffic.

**Recommendation: use it for evaluation, not for serving.** It is a genuinely good way to compare
several vision-language models against a sample of real night-time IR clips before committing to
one, without standing up any GPU infrastructure. That is worth doing, and it is worth doing early.
It cannot serve several hundred clips per night per active search at 40 RPM, and building on it
would mean rebuilding later.

Verify the current terms before relying on any of this. These figures come from third-party
summaries rather than NVIDIA's own pricing page, free tiers change, and none of it has been
tested against an account, we do not have one.

### Supabase AI: good fit, correctly scoped

`pgvector` for vector storage and similarity search, and `gte-small` in Edge Functions for text
embeddings with no external call. Both are directly useful for sighting triage. Neither addresses
image work. Correctly scoped, this is a real reduction in moving parts: no separate vector
database, no external embedding API, no extra key to manage.

### Hosted vision APIs generally

Reserved as a fallback for the case where on-device triage proves inadequate in evaluation. If we
go there, it needs an explicit privacy decision first, not an incremental slide into it.

## 5. Rejected

**General lost-pet photo matching against a listings database.** Under 2% of found cats were in a
shelter; there is no open, statewide, real-time stray feed to match against; the live data sits
behind vendor portals whose forthcoming API access reads as a partner programme rather than an
open developer surface; and Petco Love Lost already does this nationally, for free, with roughly
3,000 shelters feeding it. We would be building the hardest possible version of a feature that
addresses the smallest slice of the outcome space, in competition with a well-funded incumbent.
The protocol tells owners to use Petco Love Lost instead, on day one.

**A conversational assistant.** The owner at 11pm needs a numbered checklist and a map. A chat
interface adds latency, non-determinism and a token bill to a problem whose correct answer is
already written down and does not vary. It would demonstrate well and help nobody.

**AI-generated flyer copy.** A template produces better flyers here, the constraints are fixed
and known (large photo, few words, readable from a car, the line "may not come when called"),
and a template works offline, costs nothing, and cannot produce something strange on the worst
night of somebody's year.

**Predicting where the cat is.** Tempting, and the distance distributions look like they support
it. They do not: they are population statistics, not a per-cat prior, and dressing them up as a
heat map would manufacture false confidence about specific properties. The honest version is a
radius drawn on a map with the actual percentages written next to it, which is a circle, not a
model.

## 6. Open questions

- Detection and identity-ranking accuracy on real night IR footage. No evaluation has been run.
  This needs a labelled sample of genuine trail-camera clips before any of section 2 is committed
  to, and we have none.
- Which on-device model. Unassessed.
- Whether identity ranking adds enough over plain cat detection to justify its complexity. Plain
  detection may deliver nearly all the value.
- Current NVIDIA free-tier terms, from NVIDIA rather than from third-party summaries.
- Whether 384-dimension `gte-small` is sufficient for sighting-text similarity, or whether the
  useful signal is really in the extracted structured fields, location, time, description, with
  embeddings adding little.

## Provenance

Written by an AI agent on 2026-08-20. The open-set re-identification figures and the assessment of
shelter data availability are carried forward from this project's earlier technical research
document. NVIDIA and Supabase capability claims come from public documentation and third-party
summaries read on 2026-08-20; no account exists for either service and nothing was tested. No
person has confirmed this document.
