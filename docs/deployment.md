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

| Type | Name | Value | Proxy |
|---|---|---|---|
| `CNAME` | `kittycomehome` | `techluddite.github.io` | **DNS only** |

Two notes on that record:

- The value is the GitHub Pages apex for the account, `techluddite.github.io`, **not** the
  repository URL and not a path.
- If `opsvibe.systems` is on Cloudflare, leave the record **grey-clouded / DNS only.**
  GitHub issues the TLS certificate over an HTTP challenge, and a proxied record breaks
  that, which shows up as a certificate error that then takes a while to clear. It can be
  proxied later once the certificate exists, but there is little reason to: GitHub already
  fronts Pages with a CDN, and proxying adds Cloudflare to the list of parties who see
  visitor IP addresses, which would then need adding to the privacy page.

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

## Supabase

Nothing to deploy. The schema is applied via migrations in `supabase/migrations/`, which
match the project's migration history exactly.

The site does not hold Supabase credentials because it does not contact Supabase. When the
search tool is built, the `anon` key is safe to ship in the client because RLS is what
protects the data. The `service_role` key bypasses RLS entirely and must never reach the
client or the repository.

Free-tier projects pause after roughly a week of inactivity. That is harmless during
development and worth knowing before assuming something has broken.
