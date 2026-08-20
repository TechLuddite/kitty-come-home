-- Kitty Come Home -- initial schema
-- Applied to project ofneiwdioaelvkjuygcd on 2026-08-20.
-- Every table corresponds to something docs/protocol/ tells a person to do on paper.
--
-- NOTE: the public read path created at the end of this file was removed by
-- migration 20260820083146. Read that one before reasoning about the current state.

create extension if not exists postgis with schema extensions;
create extension if not exists vector with schema extensions;

set local search_path = public, extensions;

create type case_status as enum ('open', 'found', 'closed', 'expired');

-- 'partial' is deliberately distinct from 'searched'. The protocol is emphatic that a
-- place you could not see all of is unsearched. Collapsing these lies to the user.
create type visit_outcome as enum ('searched', 'partial', 'blocked', 'found_sign');

-- 'blocked' is the highest-value queue in the system: 11% of found cats were inside
-- someone else's building.
create type access_state as enum ('not_contacted', 'no_answer', 'granted', 'searched', 'blocked', 'declined');

create type sighting_confidence as enum ('confirmed', 'probable', 'possible', 'unlikely');
create type sighting_source as enum ('owner', 'helper', 'neighbor', 'camera', 'social', 'shelter', 'other');

create table pets (
  id              uuid primary key default gen_random_uuid(),
  owner_id        uuid not null references auth.users(id) on delete cascade,
  name            text not null,
  species         text not null default 'cat',
  indoor_only     boolean not null default true,
  description     text,
  -- Markings matter more than colour: night IR footage is greyscale.
  distinguishing_markings text,
  microchip_id    text,
  created_at      timestamptz not null default now()
);
create index pets_owner_idx on pets (owner_id);

create table cases (
  id              uuid primary key default gen_random_uuid(),
  pet_id          uuid not null references pets(id) on delete cascade,
  owner_id        uuid not null references auth.users(id) on delete cascade,
  status          case_status not null default 'open',
  -- The exact door or window, not the middle of the house.
  escape_point    geography(point, 4326) not null,
  escaped_at      timestamptz not null,
  -- Metres. Public surfaces snap the escape point to this grid.
  fuzz_radius_m   integer not null default 250,
  found_at        timestamptz,
  found_notes     text,
  -- Cases expire so an abandoned listing does not become a permanent public record
  -- of somebody's home address.
  expires_at      timestamptz not null default (now() + interval '180 days'),
  created_at      timestamptz not null default now()
);
create index cases_escape_point_idx on cases using gist (escape_point);
create index cases_open_idx on cases (status) where status = 'open';
create index cases_owner_idx on cases (owner_id);

create table pet_photos (
  id              uuid primary key default gen_random_uuid(),
  pet_id          uuid not null references pets(id) on delete cascade,
  storage_path    text not null,
  is_reference    boolean not null default false,  -- used by on-device camera triage
  created_at      timestamptz not null default now()
);
create index pet_photos_pet_idx on pet_photos (pet_id);

create table helpers (
  id              uuid primary key default gen_random_uuid(),
  case_id         uuid not null references cases(id) on delete cascade,
  user_id         uuid references auth.users(id) on delete set null,
  display_name    text,
  invited_at      timestamptz not null default now(),
  unique (case_id, user_id)
);
create index helpers_user_idx on helpers (user_id);

-- A place is an individual hiding spot, not a property. "Under the deck at number 14"
-- is a place; "number 14" is not.
create table search_places (
  id              uuid primary key default gen_random_uuid(),
  case_id         uuid not null references cases(id) on delete cascade,
  location        geography(point, 4326) not null,
  label           text not null,
  place_type      text,
  -- Distance from escape point. Ring 1 (~50m) is highest priority: the median
  -- indoor-only find is 39m.
  distance_m      numeric,
  notes           text,
  created_at      timestamptz not null default now()
);
create index search_places_location_idx on search_places using gist (location);
create index search_places_case_idx on search_places (case_id);

-- Separate from search_places because a place is searched repeatedly, at different
-- hours, with different results. A daytime search and a 2am search of the same shed
-- are two different searches.
create table search_visits (
  id              uuid primary key default gen_random_uuid(),
  place_id        uuid not null references search_places(id) on delete cascade,
  searcher_id     uuid references auth.users(id) on delete set null,
  visited_at      timestamptz not null default now(),
  is_night        boolean not null default false,
  used_flashlight boolean not null default false,
  outcome         visit_outcome not null,
  notes           text
);
create index search_visits_place_idx on search_visits (place_id, visited_at desc);

create table properties (
  id              uuid primary key default gen_random_uuid(),
  case_id         uuid not null references cases(id) on delete cascade,
  location        geography(point, 4326) not null,
  address_label   text,
  access_state    access_state not null default 'not_contacted',
  -- The two questions that find cats.
  asked_about_outbuildings boolean not null default false,
  asked_about_feeding      boolean not null default false,
  contacted_at    timestamptz,
  recanvassed_at  timestamptz,
  notes           text
);
create index properties_case_state_idx on properties (case_id, access_state);
create index properties_location_idx on properties using gist (location);

create table sightings (
  id              uuid primary key default gen_random_uuid(),
  case_id         uuid not null references cases(id) on delete cascade,
  location        geography(point, 4326) not null,
  sighted_at      timestamptz not null,
  reported_at     timestamptz not null default now(),
  source          sighting_source not null,
  confidence      sighting_confidence not null default 'possible',
  description     text,
  -- PII. Owner-visible only.
  reporter_name   text,
  reporter_phone  text,
  reporter_email  text,
  -- gte-small, 384 dimensions, generated in an Edge Function with no external call.
  -- Used for de-duplicating the same cat reported by four people.
  embedding       vector(384),
  duplicate_of    uuid references sightings(id) on delete set null
);
create index sightings_location_idx on sightings using gist (location);
create index sightings_case_time_idx on sightings (case_id, sighted_at desc);

create table stations (
  id              uuid primary key default gen_random_uuid(),
  case_id         uuid not null references cases(id) on delete cascade,
  location        geography(point, 4326) not null,
  label           text,
  has_camera      boolean not null default false,
  established_at  timestamptz not null default now(),
  last_restocked  timestamptz,
  active          boolean not null default true
);
create index stations_case_idx on stations (case_id);

-- Only events the owner CHOSE to keep. Triage runs on-device; raw clips are not
-- uploaded.
create table station_events (
  id              uuid primary key default gen_random_uuid(),
  station_id      uuid not null references stations(id) on delete cascade,
  occurred_at     timestamptz not null,
  storage_path    text,
  -- What the on-device triage thought, kept for calibration. Never authoritative:
  -- the product does not assert identity.
  triage_label    text,
  triage_score    numeric,
  owner_verdict   sighting_confidence,
  notes           text
);
create index station_events_station_idx on station_events (station_id, occurred_at desc);

create or replace function has_case_access(target_case uuid)
returns boolean language sql security definer stable
set search_path = public, extensions
as $$
  select exists (
    select 1 from cases c
    where c.id = target_case
      and (
        c.owner_id = (select auth.uid())
        or exists (select 1 from helpers h where h.case_id = c.id and h.user_id = (select auth.uid()))
      )
  );
$$;

create or replace function owns_pet(target_pet uuid)
returns boolean language sql security definer stable
set search_path = public, extensions
as $$
  select exists (select 1 from pets p where p.id = target_pet and p.owner_id = (select auth.uid()));
$$;

alter table pets            enable row level security;
alter table cases           enable row level security;
alter table pet_photos      enable row level security;
alter table helpers         enable row level security;
alter table search_places   enable row level security;
alter table search_visits   enable row level security;
alter table properties      enable row level security;
alter table sightings       enable row level security;
alter table stations        enable row level security;
alter table station_events  enable row level security;

create policy pets_owner_all on pets
  for all to authenticated
  using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));

create policy pet_photos_owner_all on pet_photos
  for all to authenticated
  using (owns_pet(pet_id)) with check (owns_pet(pet_id));

create policy cases_owner_all on cases
  for all to authenticated
  using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));

create policy cases_helper_read on cases
  for select to authenticated using (has_case_access(id));

-- The case owner manages the helper list; a helper can see their own row.
create policy helpers_owner_all on helpers
  for all to authenticated
  using (exists (select 1 from cases c where c.id = case_id and c.owner_id = (select auth.uid())))
  with check (exists (select 1 from cases c where c.id = case_id and c.owner_id = (select auth.uid())));

create policy helpers_self_read on helpers
  for select to authenticated using (user_id = (select auth.uid()));

create policy places_case_access on search_places
  for all to authenticated
  using (has_case_access(case_id)) with check (has_case_access(case_id));

create policy visits_case_access on search_visits
  for all to authenticated
  using (exists (select 1 from search_places sp where sp.id = place_id and has_case_access(sp.case_id)))
  with check (exists (select 1 from search_places sp where sp.id = place_id and has_case_access(sp.case_id)));

create policy properties_case_access on properties
  for all to authenticated
  using (has_case_access(case_id)) with check (has_case_access(case_id));

create policy stations_case_access on stations
  for all to authenticated
  using (has_case_access(case_id)) with check (has_case_access(case_id));

create policy station_events_case_access on station_events
  for all to authenticated
  using (exists (select 1 from stations s where s.id = station_id and has_case_access(s.case_id)))
  with check (exists (select 1 from stations s where s.id = station_id and has_case_access(s.case_id)));

create policy sightings_public_insert on sightings
  for insert to anon, authenticated
  with check (exists (select 1 from cases c where c.id = case_id and c.status = 'open' and c.expires_at > now()));

create policy sightings_case_read on sightings
  for select to authenticated using (has_case_access(case_id));

create policy sightings_case_write on sightings
  for update to authenticated
  using (has_case_access(case_id)) with check (has_case_access(case_id));

create view public_cases
with (security_invoker = off) as
select
  c.id, p.name as pet_name, p.species, p.description, p.distinguishing_markings,
  c.escaped_at, c.status, c.fuzz_radius_m,
  st_snaptogrid(c.escape_point::geometry, (c.fuzz_radius_m / 111320.0)::double precision)::geography as approx_area
from cases c join pets p on p.id = c.pet_id
where c.status = 'open' and c.expires_at > now();

revoke all on all tables in schema public from anon, authenticated;

grant select, insert, update, delete on
  pets, pet_photos, cases, helpers, search_places, search_visits,
  properties, stations, station_events
  to authenticated;

grant select, insert, update on sightings to authenticated;
grant select on public_cases to anon, authenticated;
grant insert on sightings to anon;
