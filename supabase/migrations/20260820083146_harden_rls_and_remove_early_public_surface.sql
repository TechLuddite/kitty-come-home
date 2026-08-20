-- Security hardening, in response to the database linter.
--
-- 1. Remove the public read path entirely for now.
--
--    `public_cases` was a SECURITY DEFINER view: it read past RLS so that anon could
--    see a fuzzed case list without being granted `cases`. That works, but it makes
--    the view's column list the only thing standing between the public and somebody's
--    home address, and the linter is right to flag it.
--
--    The public case page is Phase 2 work and nothing needs it yet. Shipping an
--    unauthenticated read path and an unauthenticated, unrate-limited write path
--    ahead of need is the wrong trade. Both are removed.
--
--    The intended Phase 2 design, recorded here so it is not re-derived: keep the
--    exact escape point unreadable by using COLUMN-LEVEL grants rather than a
--    definer view. Add a stored generated column holding the snapped geography,
--    grant anon SELECT on only the safe columns of `cases` and `pets`, add an RLS
--    policy for open non-expired cases, and make the view security_invoker = on.
--    anon then cannot read `escape_point` even by querying the table directly,
--    because the privilege does not exist rather than because a view omitted it.
--
-- 2. Move the RLS helper functions out of the API-exposed schema.
--
--    Both were SECURITY DEFINER in `public`, so PostgREST exposed them at
--    /rest/v1/rpc/. They exist to be called from policy expressions, never over
--    HTTP. Moving them to `private` removes them from the API surface.
--
-- WARNING: this migration also revoked EXECUTE on those functions, which broke every
-- policy that calls them. See 20260820083440 for the fix and the reasoning.

drop view if exists public_cases;

revoke select on all tables in schema public from anon;
revoke insert on sightings from anon;
drop policy if exists sightings_public_insert on sightings;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

alter function public.has_case_access(uuid) set schema private;
alter function public.owns_pet(uuid) set schema private;

revoke all on function private.has_case_access(uuid) from public, anon, authenticated;
revoke all on function private.owns_pet(uuid) from public, anon, authenticated;

-- Supabase's own automatic-RLS event trigger function. It is an event trigger
-- function, so an RPC call to it errors rather than doing anything, but there is no
-- reason for it to be on the API surface.
revoke all on function public.rls_auto_enable() from public, anon, authenticated;
