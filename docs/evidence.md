# Evidence base

Version 1 to 2026-08-20.

Everything in this repository that makes a factual claim about cat behaviour or recovery should
trace back to this document. Where the evidence is weak, this says so. Where two sources
disagree, both are given.

## 1. Summary

The design rests on four findings, in descending order of how much weight they carry:

1. Escaped indoor-only cats are found very close to home, median 39 m.
2. Under 2% of found cats were found in a shelter.
3. Physical searching of the immediate area is the recovery method with the strongest signal,
   though the association falls just short of conventional significance.
4. Microchipping showed no detectable effect on recovery in this dataset, which is not an
   argument against microchipping, and is explained in section 5.

## 2. Primary source

**Huang L., Coradini M., Rand J., Morton J., Albrecht K., Wasson B., Robertson D. (2018).
"Search Methods Used to Locate Missing Cats and Locations Where Missing Cats Are Found."
*Animals* 8(1):5.** <https://doi.org/10.3390/ani8010005>

Retrospective case series, n = 1,210, self-selected participants reporting via online
questionnaire, University of Queensland.

### Recovery over time

| Interval | Found alive | 95% CI |
|---|---|---|
| Day 7 | 34% | 31 to 37% |
| Day 30 | 50% | 47 to 53% |
| Day 61 | 56% | 53 to 59% |
| One year | 61% | 57 to 64% |

The first week carries a disproportionate share of the outcome. This is the single strongest
argument for front-loading effort, and it is why the protocol is organised around the first 24
hours rather than a steady-state search.

### Distance from point of escape

| Cat type | Median | 25th to 75th percentile |
|---|---|---|
| Indoor-only | **39 m** | 9 to 137 m |
| Indoor-outdoor, unsupervised access | 300 m | 14 to 1,609 m |

75% of all cats were found within 500 m of the point of escape. The difference between the two
groups was significant (p ≤ 0.001).

Note the interquartile range on indoor-only cats: 9 to 137 m. Even the upper quartile is inside a
radius most people can walk in a few minutes. This is the number that makes a systematic
close-range search worth doing properly rather than quickly.

### Where cats were found

| Location | Share |
|---|---|
| Outside | 83% |
| Inside someone else's house or building | 11% |
| Inside their own house | 4% |
| Inside a public building | 2% |
| **In a shelter** | **under 2%** |

The 4% found inside their own home is worth its own line in the protocol. Search the house
first, thoroughly, before assuming the cat got out at all.

The 11% found inside a neighbour's property is the reason the neighbour canvass is a distinct
protocol step rather than a footnote. The owner physically cannot search those places
themselves; someone has to ask.

### Search methods

Physical searching showed evidence of an association with finding the cat alive at **p = 0.071**.

Stated honestly: that is a positive signal that does not clear the conventional 0.05 threshold.
It is the strongest method signal in the study, and it is consistent with the distance findings
and with MAR field experience, but this study does not *prove* physical search works. The
specific tactics reported most often alongside recovery were searching the immediate area,
calling the cat's name, walking during daytime, and help from neighbours.

We treat physical search as the recommended approach because three independent lines of
evidence point the same way, not because any one of them is conclusive.

## 3. Missing Animal Response case data

Kat Albrecht's Missing Animal Response Network, an author on the study above, reports from its
own case files that displaced indoor-only cats are found at a median of about **50 m**, and that
**92% of 158 cases** of displaced indoor-only cats were found within a five-house radius.

<https://www.missinganimalresponse.com/lost-cat-behavior/>

This is case-series data from a practice, not a controlled study, and the sample is smaller. It
agrees closely with the peer-reviewed median of 39 m, which is reassuring. Where this document
cites a distance, it uses the 39 m figure from the published study and treats the MAR five-house
radius as a useful rule of thumb for the same phenomenon.

### Behavioural model

MAR categorises lost cat behaviour into displaced indoor cats, displaced outdoor cats, and lost
outdoor cats. The relevant claim for this project is that a panicked indoor cat's response is to
bolt a short distance and hide, and that it will often not respond to its name even when the
owner is within a few metres, particularly in the first day or two.

The word doing the work there is "often". This is a tendency, not a rule, and the same study
records calling the cat's name among the tactics reported alongside recovery. Response very
plausibly varies with the individual cat, its recent experience, elapsed time and who is calling,
none of which the data separates. The defensible claim is that **silence is weak evidence of
absence**, not that a displaced cat will not answer.

This is a behavioural model reported by practitioners rather than a controlled finding, and it is
the load-bearing assumption behind the night-search and feeding-station steps. If it is wrong,
several protocol steps are wrong with it. It is consistent with the distance data, which is the
main reason to trust it.

## 4. Cats versus dogs

The market research on this project cited a Faunalytics analysis putting US shelter
return-to-owner for cats near **3%**, against roughly **40%** for dogs.

Treat those as approximate and advocacy-sourced. The direction is not in dispute and is
corroborated by the under-2%-found-in-a-shelter figure above: cats do not reach the shelter
system the way dogs do, so a recovery pipeline that runs through shelters mostly does not run.

## 5. Microchips

Microchipping showed **no statistically detectable improvement** in recovery in this dataset
(46% of cats were chipped; p = 0.331).

This is easy to misread. It is not evidence that microchips are useless, and nothing in this
project should be taken as discouraging microchipping. The most likely explanation is the same
one as everything else here: a microchip only helps if someone scans it, scanning happens at
shelters and vets, and under 2% of these cats reached one. The chip works fine, the cat just
never got to a scanner.

Keep your cat chipped and keep the registration current. Then go search the neighbour's shed.

## 6. Regulatory: California stray cat holding period

California Food and Agricultural Code § 31752 sets the required hold for an impounded stray cat
at **six business days**, not counting the day of impoundment. It is reduced to **four business
days** where the shelter either offers owner redemption on one weekday evening until at least
7pm or one weekend day, or has fewer than three full-time employees and an appointment process
for reclaiming outside normal hours. Stray cats are held for owner redemption during the first
three days, and are available for redemption or adoption for the remainder.

<https://california.public.law/codes/ca_food_and_agric_code_section_31752>

This closes an open question carried in the project's earlier technical research, which recorded
the hold period as unresolved between conflicting agency summaries of 72 hours and four business
days. Those summaries appear to have described dogs or local policy. The statute is the
authority, and the cat figure is six business days reducible to four.

Read from a statute aggregator rather than from the legislature's own text. Verify before relying
on it for anything consequential.

## 7. What this document does not establish

- **Whether software improves on the paper protocol.** Unmeasured. It is the central assumption
  of the whole project and it is untested. The protocol is evidence-based; the app is a bet.
- **Camera triage accuracy in the field.** No evaluation has been run. The published re-ID
  figures cited in the AI scope document are from academic benchmarks on curated datasets, not
  from night-time infrared footage of a feeding station.
- **Whether any of this generalises outside a suburban residential setting.** The distance
  findings come from a self-selected sample skewed toward owners engaged enough to complete a
  questionnaire. Dense urban apartments and rural properties may behave differently.
- **Non-US, non-Australian applicability.** Both main sources are US and Australian.

## Provenance

Compiled 2026-08-20 by an AI agent from the sources linked above: the Huang et al. paper via
PubMed Central, the MAR Network's published case data, and a statute aggregator for § 31752. The
paper's figures were taken from the article text rather than from secondary summaries, an
intermediate search summary of this same paper misreported the indoor-only median as 137 m, which
is in fact the 75th percentile. Where this document cites the paper, the figure came from the
article.

No person has confirmed this document. Corrections are welcome and are the most valuable
contribution anyone can make to this repository.
