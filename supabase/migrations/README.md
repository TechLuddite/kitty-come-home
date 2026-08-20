# Migrations

These files are the record of what is applied to the Supabase project
`ofneiwdioaelvkjuygcd` (`Kitty Come Home`, us-west-1, Postgres 17.6). They are listed
in the order they were applied and they match the project's migration history.

| # | Migration | What it did |
|---|---|---|
| 1 | `..._init_kitty_come_home.sql` | Tables, enums, indexes, RLS policies, and a first public read path. |
| 2 | `..._harden_rls_and_remove_early_public_surface.sql` | Removed the public read and write paths; moved the RLS helper functions out of the API-exposed schema. |
| 3 | `..._restore_execute_on_private_rls_helpers.sql` | Fixed a break introduced by 2. See below. |

## The bug worth remembering

Migration 2 both moved the RLS helper functions to a `private` schema *and* revoked
EXECUTE on them. Moving them was correct and removed them from the PostgREST surface.
Revoking EXECUTE was wrong: a policy expression is evaluated as the querying role, so
that role needs EXECUTE on every function the policy calls. The result was that every
policy referencing `has_case_access` failed with `permission denied for function`,
while the Supabase security linter reported completely clean.

The linter checks configuration. It does not check that the database still works. This
was caught by an RLS behaviour test that asserts who can read what, which is why that
test exists and should be run after any policy change.

## Verifying

The behaviour test seeds an owner, a helper and an unrelated user, then asserts the
fourteen access outcomes that matter, including that `anon` gets a privilege error
rather than an empty result. Privilege errors are the stronger property: there is no
grant for a future RLS mistake to leak through.

Current state: 14/14 passing, security advisors clean.
