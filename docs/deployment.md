# Deployment

Version 1 to 2026-08-20.

## Summary

The site is static, hosted on GitHub Pages at **kittycomehome.opsvibe.systems**, and
deployed by GitHub Actions on every push to `main` that touches `site/`. It has no build
step, no dependencies and no backend. The Supabase project exists but the site does not
talk to it.

## What is live

| Thing | State |
|---|---|
| `site/` static protocol site | Built and tested. Waiting on the two manual steps below. |
| Supabase project `Kitty Come Home` (`ofneiwdioaelvkjuygcd`, us-west-1) | Live. Schema applied, RLS verified, advisors clean. |
| Public read/write API surface | **None.** Deliberately removed, see ADR 0004 and migration `20260820083146`. |

## The two things only a human can do

**1. Make the repository public and turn Pages on.**

GitHub Pages needs a public repository on the free plan.

- Settings → General → Danger Zone → Change visibility → Public
- Settings → Pages → Build and deployment → Source: **GitHub Actions**
- Settings → Pages → Custom domain: `kittycomehome.opsvibe.systems`, then Save
- Tick **Enforce HTTPS** once the certificate has been issued, which takes a few minutes

The `site/CNAME` file already carries the domain, so the custom domain field should
populate on the first deploy.

**2. Create one DNS record.**

`opsvibe.systems` is registered at Spaceship and uses Spaceship nameservers
(`launch1.spaceship.net`, `launch2.spaceship.net`), verified 2026-08-20. Add this in
Spaceship's Advanced DNS for the domain:

| Type | Host | Value | TTL |
|---|---|---|---|
| `CNAME` | `kittycomehome` | `techluddite.github.io` | Automatic |

Notes on that record:

- **The value comes from GitHub, not from Supabase.** It is the account's GitHub Pages
  apex, `techluddite.github.io`. It is not the repository URL, not a path, and there is
  nothing to look up: the form is always `<github-username>.github.io`. Confirmed live, it
  resolves to the GitHub Pages addresses `185.199.108.153` through `185.199.111.153`.
- Enter the host as just `kittycomehome`, not the full domain. Spaceship appends the zone.
- Spaceship is a plain authoritative DNS provider with no proxy layer, so there is no
  orange-cloud equivalent to worry about. If the domain ever moves to Cloudflare, the
  record must stay unproxied until GitHub has issued the certificate, because a proxied
  record breaks the HTTP challenge.
- `opsvibe.systems` currently has **no CAA record**, verified 2026-08-20, so nothing blocks
  GitHub from issuing a Let's Encrypt certificate. If a CAA record is added later it needs
  `letsencrypt.org` in it or HTTPS on this subdomain will break at renewal.

Propagation is usually minutes. GitHub re-checks the domain on a schedule, so if it reports
the DNS as unverified immediately after you create the record, give it ten minutes.

## Verifying it worked

1. `https://kittycomehome.opsvibe.systems` loads and redirects to HTTPS.
2. Open developer tools, Network tab, hard reload. **There should be no request to any
   origin other than the site itself.** The privacy page makes that promise in public, and
   the deploy workflow fails the build if a third-party subresource appears in `site/`.
3. Load the page once, turn off the network, reload. It should still work: the service
   worker caches it, which is the whole point for someone in a garden with no signal.
4. Print preview. The protocol should come out as a clean handout with the checkboxes and
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
