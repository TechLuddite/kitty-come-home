# Deployment

Version 2 to 2026-08-20.

## Summary

The site is static, hosted on GitHub Pages at **kittycomehome.org**, and deployed by
GitHub Actions on every push to `main` that touches `site/`. It has no build step, no
dependencies and no backend. The Supabase project exists but the site does not talk to it.

The apex is a product decision rather than a vanity one. The reader is frightened, on a
phone, often at 2am, and every character they have to type is a character they can get
wrong. `kittycomehome.org` is the shortest path to the protocol, so the protocol is what
sits there. Longer addresses are for everyone else: contributors get the repository, and
`www` redirects to the apex rather than serving a second copy of the site.

## What is live

| Thing | State |
|---|---|
| `site/` static protocol site | Live at `kittycomehome.org`. |
| Supabase project `Kitty Come Home` (`ofneiwdioaelvkjuygcd`, us-west-1) | Live. Schema applied, RLS verified, advisors clean. |
| Public read/write API surface | **None.** Deliberately removed, see ADR 0004 and migration `20260820083146`. |

## The domain

`kittycomehome.org` is ours and uses **Cloudflare** nameservers (`keira.ns.cloudflare.com`,
`elias.ns.cloudflare.com`), verified 2026-08-20.

Two addresses that are *not* ours, recorded here so nobody loses an afternoon to them:

- **`kittycomehome.com` belongs to someone else.** Registered 2025-12-19 to a third party,
  parked on Afternic's nameservers and serving a for-sale lander. It cannot be configured,
  only bought on the aftermarket.
- **`kittycomehome.opsvibe.systems` is retired.** It was the original address and stopped
  serving the moment the Pages custom domain changed. It is not coming back.
- **`help.kittycomehome.org` is gone.** It briefly served the site while the apex was being
  set up, and its `CNAME` was removed once the apex took over. Anything pointing at it now
  fails to resolve. If it ever needs to come back it is one unproxied `CNAME` to
  `techluddite.github.io`, and GitHub will redirect it to the apex.

### The records

An apex domain cannot be a `CNAME`. That is the whole difference from the old subdomain
setup, and the reason a straight repeat of the previous recipe does not work here: the apex
needs address records pointing at GitHub's Pages servers. In the Cloudflare dashboard for
`kittycomehome.org`, under DNS → Records:

| Type | Name | Value | Proxy | TTL |
|---|---|---|---|---|
| `A` | `@` | `185.199.108.153` | **DNS only** | Auto |
| `A` | `@` | `185.199.109.153` | **DNS only** | Auto |
| `A` | `@` | `185.199.110.153` | **DNS only** | Auto |
| `A` | `@` | `185.199.111.153` | **DNS only** | Auto |
| `AAAA` | `@` | `2606:50c0:8000::153` | **DNS only** | Auto |
| `AAAA` | `@` | `2606:50c0:8001::153` | **DNS only** | Auto |
| `AAAA` | `@` | `2606:50c0:8002::153` | **DNS only** | Auto |
| `AAAA` | `@` | `2606:50c0:8003::153` | **DNS only** | Auto |
| `CNAME` | `www` | `techluddite.github.io` | **DNS only** | Auto |

Notes on those records:

- **Grey cloud, never orange.** Every record must be DNS only. Proxying puts Cloudflare's
  addresses in front of GitHub's, which breaks the HTTP challenge GitHub uses to issue the
  certificate and can leave a redirect loop behind afterwards. The short-lived `help` record
  was DNS only, which is why the certificate for it issued without trouble, and the apex
  records were created the same way.
- **All four `A` records, not one.** GitHub publishes four and expects all four. One record
  is a single point of failure for no benefit.
- The `AAAA` records are optional but free, and IPv6-only mobile networks are real. Verified
  2026-08-20 as the current addresses behind `techluddite.github.io`.
- The apex records are live, verified 2026-08-20: all four `A` records, all four `AAAA`
  records, a Let's Encrypt certificate issued for `kittycomehome.org`, and Enforce HTTPS on.
- **`www` is not created yet.** It is the one record still worth adding: people type it out
  of habit, and without it they get a DNS failure rather than the site. Once it exists it
  needs nothing further, because GitHub redirects it to the apex on its own whenever the
  apex is the configured custom domain. No second copy of the site, no redirect rule.
- The value `techluddite.github.io` is the **account's** Pages apex. It is not the
  repository URL and not a path: the form is always `<github-username>.github.io`.
- `kittycomehome.org` has **no CAA record**, verified 2026-08-20, so nothing blocks GitHub
  from issuing a Let's Encrypt certificate. If a CAA record is ever added it needs
  `letsencrypt.org` in it, or HTTPS breaks at the next renewal.

Propagation is usually minutes. GitHub re-checks the domain on a schedule, so if it reports
the DNS as unverified straight after you create the records, give it ten minutes.

### The order matters

This is the part that is easy to get backwards, and getting it backwards is what took the
site down once already:

1. **DNS records first.** Create them, and confirm they resolve before touching GitHub.
2. **Then `site/CNAME`.** It is the source of truth for the custom domain. The Pages source
   is GitHub Actions, and Pages reads the CNAME out of the published artifact on every
   single deploy.
3. **Then the Settings page, only if it still disagrees.** Setting the custom domain under
   Settings → Pages does work, but the next deploy overwrites it with whatever `site/CNAME`
   says. Setting it in the UI while `site/CNAME` still held the old value is exactly how the
   old address went dark while the repository was still claiming it, one push away from
   silently reverting the new one.
4. **Then Enforce HTTPS**, under Settings → Pages, once the certificate has been issued.
   The tick box stays greyed out until it has.

The `verify` job in the deploy workflow asserts that `site/CNAME` matches the expected
domain, so drift between the repository and the live site fails the build instead of
quietly moving the site out from under its readers.

## Repository visibility

GitHub Pages needs a public repository on the free plan, and this one is public. The
workflow passes `enablement: true` to `actions/configure-pages`, which turns Pages on and
sets the source to GitHub Actions over the API, so no one has to visit Settings before the
first deploy. The very first run predated that parameter and failed with
`Get Pages site failed ... Not Found`, which is what it exists to prevent.

## Verifying it worked

1. `https://kittycomehome.org` loads, and the `http://` form redirects to it.
2. Once the `www` record exists, `https://www.kittycomehome.org` redirects to the apex
   rather than serving its own copy.
3. Open developer tools, Network tab, hard reload. **There should be no request to any
   origin other than the site itself.** The privacy page makes that promise in public, and
   the deploy workflow fails the build if a third-party subresource appears in `site/`.
4. Load the page once, turn off the network, reload. It should still work: the service
   worker caches it, which is the whole point for someone in a garden with no signal.
5. Print preview. The protocol should come out as a clean handout with the checkboxes and
   without the navigation.

## The deploy workflow

`.github/workflows/pages.yml` runs two jobs.

`verify` fails the build if `site/` gains a third-party subresource or if `site/CNAME`
stops matching the expected domain. The privacy page states that this site contacts nobody,
so that claim is enforced at deploy time rather than trusted. If you add a legitimate
outbound link, add the domain to the allowlist in that job **and** to the third-party table
in `site/privacy.html`. Those two should never drift apart.

`deploy` uploads `site/` and publishes it. Concurrency is set to not cancel a running
deploy, because a half-published page is worse than a slightly stale one.

## Changing the site

Edit files in `site/`, push to `main`, and it deploys. Two things to remember:

- **Bump `CACHE` in `site/sw.js`** when content changes. The service worker is
  network-first, so returning visitors get fresh content anyway, but the version bump is
  what clears the old cached copies.
- **Re-run the browser tests.** They check for external requests, JavaScript errors,
  horizontal overflow at 390px, that every checkbox and the night mode survive a reload,
  that all links and anchors resolve, that no tap target is under 44px, and that no text
  breaks the page gutter. That last one exists because a padding shorthand on `header.top`
  silently overrode the page gutter and pushed the hero text to the screen edge, which
  looked fine in the markup and only showed up in a screenshot.

## Why GitHub Pages and not Supabase

Supabase is a database, an auth service, object storage and a function runtime. It is not a
static web host: there is no way to point a custom domain at a set of HTML files on the
free tier, and Supabase's own custom-domain feature is a paid add-on that applies to the API
endpoint rather than to hosting a site.

The split is that GitHub Pages serves the pages, and Supabase holds the case data once the
search tool exists. Right now the site contains no code that contacts Supabase at all.

Keeping the protocol on a dumb static host is a deliberate choice rather than a stopgap. It
has no backend that can fail, it caches itself for offline use, and it does not depend on a
database being awake. That last point is concrete: **free-tier Supabase projects pause after
roughly a week of inactivity.** If the protocol were served from Supabase, a quiet week
would take the site down, and the whole argument for this project is that the page has to
work at 2am on the worst night of somebody's year.

## Supabase

Nothing to deploy. The schema is applied via migrations in `supabase/migrations/`, which
match the project's migration history exactly.

The site does not hold Supabase credentials because it does not contact Supabase. When the
search tool is built, the `anon` key is safe to ship in the client because RLS is what
protects the data. The `service_role` key bypasses RLS entirely and must never reach the
client or the repository.

Free-tier projects pause after roughly a week of inactivity. That is harmless during
development and worth knowing before assuming something has broken.
