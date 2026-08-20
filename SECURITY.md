# Security policy

## Reporting a vulnerability

Please **do not open a public issue** for a security vulnerability.

Report it privately through GitHub's [private vulnerability
reporting](https://github.com/TechLuddite/kitty-come-home/security/advisories/new), or contact the repository owner directly.

Expect an acknowledgement within a few days. This is a small volunteer project; it is not a
24-hour operation, and I would rather say that than promise a response time nobody can keep.

## What we consider security-sensitive

The usual categories, plus two that carry unusual weight here because of what this application
holds:

**Location disclosure.** Anything that exposes a case's precise escape point to somebody who is
not the owner or an invited helper. The escape point is a home address belonging to a distressed
person, and disclosing it is treated as a serious vulnerability rather than a privacy nit. See
[`docs/adr/0004`](docs/adr/0004-privacy-and-location-handling.md).

**Sighting reporter PII.** Names, phone numbers and email addresses of members of the public who
reported a sighting are visible only to the case team. Any path that widens that is in scope.

Also in scope: row-level security bypasses, authentication and authorisation flaws, unauthorised
access to stored photos or camera footage, and injection of any kind.

## Scope

This repository. There is no deployed instance yet, the project is greenfield and no Supabase
project exists. When one does, this section will name it.

## Supported versions

Nothing is released. Once something is, this will say which versions receive fixes.
