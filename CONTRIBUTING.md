# Contributing

Contributions are welcome. This is a small project with a narrow goal — help people find escaped
indoor cats faster — and the most valuable contributions are not necessarily code.

## What helps most

**1. Corrections to the protocol.**

[`docs/protocol/`](docs/protocol/) is the part where being wrong has a real cost. If you do this
work — shelter or rescue staff, TNR trappers, MAR-trained searchers, animal control, or someone
who found their own cat and learned something the hard way — and something here is wrong,
misleading, or missing, please [open an issue](https://github.com/TechLuddite/kitty-come-home/issues/new/choose).

Field experience counts as evidence here. You do not need a citation. Tell us what happened, what
you did, and what worked. If it contradicts what is written, that is exactly the issue we want.

**2. Real night infrared trail-camera footage, labelled.**

Phase 3 cannot start without an evaluation set, and academic benchmarks on curated datasets are
poor evidence for greyscale IR clips of a feeding station at 3am. If you have footage you are
willing to share, please open an issue before uploading anything — we need to sort out consent and
privacy first, since these clips often contain other people's property.

**3. Translation.** Spanish first.

**4. Code.** See below.

## Ground rules

**Evidence beats opinion, and field experience is evidence.** Any change to a factual claim needs
to update [`docs/evidence.md`](docs/evidence.md) too, with a source. Where the evidence is weak,
say so in the document rather than rounding it up to confident.

**Do not overstate.** This project's credibility rests on being honest about what is known. If a
finding is a single case series, or a practitioner's model rather than a controlled study, the
document says that. Please keep it that way.

**Protocol changes are held to a higher bar than code changes.** Someone may follow these
instructions at 2am with their cat's life in the balance. Changes need reasoning, and preferably a
source or direct field experience.

**Respect the scope.** [`docs/adr/`](docs/adr/) records what this project decided not to build and
why — shelter aggregation, photo matching against listings, chatbots, dogs. These are not
oversights. If you think one is wrong, open an issue arguing the case and bring evidence; a pull
request implementing it will not be merged on its own.

**Privacy is not negotiable.** [`docs/adr/0004`](docs/adr/0004-privacy-and-location-handling.md)
sets out how location and video are handled. A change that would publish a precise home location,
upload camera footage by default, or expose a sighting reporter's contact details will be
rejected regardless of what else it does.

## Code

Nothing is built yet, so there is unusual freedom here — and correspondingly, please open an issue
to discuss anything substantial before writing it. The front-end framework is deliberately
unchosen, waiting on a contributor with a preference and the willingness to maintain it.

When there is code, the expectations will be the ordinary ones: it runs, it has tests where tests
make sense, and the pull request explains what changed and why.

Schema changes go in [`supabase/migrations/`](supabase/migrations/) as plain SQL, one migration
per change, never edited after being applied.

## Commits and pull requests

Clear messages describing what changed and why. Small, focused pull requests. Reference the issue
if there is one.

## Conduct

See [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md). Briefly: people arrive here upset, sometimes
having lost an animal. Be kind, particularly in issues where somebody is describing a search that
did not end well.

## Licence

Contributions are accepted under the repository's licences: MIT for code, CC BY 4.0 for
documentation. See [`LICENSE`](LICENSE).
