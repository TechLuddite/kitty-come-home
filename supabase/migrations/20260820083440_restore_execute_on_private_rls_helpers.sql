-- The previous migration revoked EXECUTE on the RLS helper functions as well as
-- moving them out of the API-exposed schema. Moving them was right. Revoking EXECUTE
-- was wrong: a policy expression is evaluated as the querying role, so that role needs
-- EXECUTE on any function the policy calls. Every policy referencing has_case_access
-- started failing with "permission denied for function has_case_access", while the
-- security linter reported clean. Caught by an RLS behaviour test, not by the linter.
--
-- The API exposure concern is handled by the schema move on its own: PostgREST serves
-- `public` (and any schema explicitly configured), so nothing in `private` is
-- reachable over HTTP regardless of who holds EXECUTE.
--
-- anon is deliberately left without access. No remaining policy references these
-- functions for anon, and there is no public read path at present.

grant usage on schema private to authenticated;
grant execute on function private.has_case_access(uuid) to authenticated;
grant execute on function private.owns_pet(uuid) to authenticated;
