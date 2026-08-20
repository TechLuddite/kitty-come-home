-- Kitty Come Home — initial schema
--
-- Status: SKETCH. Not applied anywhere; there is no Supabase project yet.
-- The RLS policies below express the intent of docs/adr/0004 but have NOT been
-- reviewed adversarially. Do not put a live instance behind this without that review.
--
-- Every table here corresponds to something docs/protocol/ tells a person to do on paper.

create extension if not exists postgis;
create extension if not exists vector;
create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------

create type case_status as enum ('open', 'found', 'closed', 'expired');

-- 'partial' is deliberately distinct from 'searched'. The protocol is emphatic that a
-- place you could not see all of is unsearched. Collapsing these lies to the user.
create type visit_outcome as enum ('searched', 'partial', 'blocked', 'found_sign');

-- 'blocked' is the highest-value queue in the system: 11% of found cats were inside
-- someone else's building. See docs/protocol/neighbor-canvass.md.
create type access_state as enum ('not_contacted', 'no_answer', 'granted', 'searched', 'blocked', 'declined');

create type sighting_confidence as enum ('confirmed', 'probable', 'possible', 'unlikely');
create type sighting_source as enum ('owner', 'helper', 'neighbor', 'camera', 'social', 'shelter', 'other');

-- ---------------------------------------------------------------------------
-- Core
-- ---------------------------------------------------------------------------

create table pets (
  id              uuid primary key default gen_random_uuid(),
  name            text not null,
  species         text not null default 'cat',
  indoor_only     boolean not null default true,
  description     text,
  -- Markings matter more than colour: night IR footage is greyscale.
  -- See docs/protocol/feeding-station-and-camera.md.
  distinguishing_markings text,
  microchip_id    text,
  created_at      timestamptz not null default now()
);

create table cases (
  id              uuid primary key default gen_random_uuid(),
  pet_id          uuid not null references pets(id) on delete cascade,
  owner_id        uuid not null references auth.users(id) on delete cascade,
  status          case_status not null default 'open',

  -- The exact door or window, not the middle of the house. Never exposed publicly
  -- at full precision -- see the public_cases view and docs/adr/0004.
  escape_point    geography(point, 4326) not null,
  escaped_at      timestamptz not null,

  -- Metres. Public views round the escape point to this grid.
  fuzz_radius_m   integer not null default 250,

  found_at        timestamptz,
  found_notes     text,

  -- Cases expire so that an abandoned listing does not become a permanent public
  -- record of somebody's home address. See docs/adr/0004.
  expires_at      timestamptz not null default (now() + interval '180 days'),
  created_at      timestamptz not null default now()
);

create index cases_escape_point_idx on cases using gist (escape_point);
create index cases_status_idx on cases (status) where status = 'open';

create table pet_photos (
  id              uuid primary key default gen_random_uuid(),
  pet_id          uuid not null references pets(id) on delete cascade,
  storage_path    text not null,
  is_reference    boolean not null default false,  -- used by on-device camera triage
  created_at      timestamptz not null default now()
);

create table helpers (
  id              uuid primary key default gen_random_uuid(),
  case_id         uuid not null references cases(id) on delete cascade,
  user_id         uuid references auth.users(id) on delete set null,
  display_name    text,
  invited_at      timestamptz not null default now(),
  unique (case_id, user_id)
);

-- ---------------------------------------------------------------------------
-- Search grid -- docs/protocol/search-grid.md
-- ---------------------------------------------------------------------------

-- A place is an individual hiding spot, not a property. "Under the deck at number 14"
-- is a place; "number 14" is not.
create table search_places (
  id              uuid primary key default gen_random_uuid(),
  case_id         uuid not null references cases(id) on delete cascade,
  location        geography(point, 4326) not null,
  label           text not null,
  place_type      text,  -- deck | shed | crawlspace | vehicle | culvert | woodpile | ...
  -- Distance from escape point, denormalised for ring queries. Ring 1 (~50m) is
  -- highest priority: the median indoor-only find is 39m.
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

-- ---------------------------------------------------------------------------
-- Neighbour canvass -- docs/protocol/neighbor-canvass.md
-- ---------------------------------------------------------------------------

create table properties (
  id              uuid primary key default gen_random_uuid(),
  case_id         uuid not null references cases(id) on delete cascade,
  location        geography(point, 4326) not null,
  address_label   text,
  access_state    access_state not null default 'not_contacted',
  -- The two questions that find cats. See the canvass script.
  asked_about_outbuildings boolean not null default false,
  asked_about_feeding      boolean not null default false,
  contacted_at    timestamptz,
  recanvassed_at  timestamptz,
  notes           text
);

create index properties_case_state_idx on properties (case_id, access_state);
create index properties_location_idx on properties using gist (location);

-- ---------------------------------------------------------------------------
-- Sightings
-- ---------------------------------------------------------------------------

create table sightings (
  id              uuid primary key default gen_random_uuid(),
  case_id         uuid not null references cases(id) on delete cascade,
  location        geography(point, 4326) not null,
  sighted_at      timestamptz not null,
  reported_at     timestamptz not null default now(),
  source          sighting_source not null,
  confidence      sighting_confidence not null default 'possible',
  description     text,

  -- PII. Owner-visible only -- see the RLS policy below and docs/adr/0004.
  reporter_name   text,
  reporter_phone  text,
  reporter_email  text,

  -- gte-small, 384 dimensions, generated in an Edge Function with no external call.
  -- Used for de-duplicating the same cat reported by four people.
  -- See docs/ai-scope.md section 3.
  embedding       vector(384),

  duplicate_of    uuid references sightings(id) on delete set null
);

create index sightings_location_idx on sightings using gist (location);
create index sightings_case_time_idx on sightings (case_id, sighted_at desc);

-- ---------------------------------------------------------------------------
-- Feeding stations -- docs/protocol/feeding-station-and-camera.md
-- ---------------------------------------------------------------------------

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

-- Only events the owner CHOSE to keep. Triage runs on-device; raw clips are not
-- uploaded. See docs/adr/0003 and docs/adr/0004.
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

-- ---------------------------------------------------------------------------
-- Public view -- fuzzed location only
-- ---------------------------------------------------------------------------

-- Public case pages get a rounded centroid, never the escape point. A precise pin
-- is a published home address. See docs/adr/0004.
--
-- NOTE: this view is the deliberate public escape hatch from RLS. Postgres views run
-- with the definer's rights by default and so bypass row-level security on `cases`.
-- That is intended here -- but it means this column list is a security boundary.
-- Never add a column to it that carries exact location or any PII.
create view public_cases as
select
  c.id,
  p.name         as pet_name,
  p.species,
  p.description,
  p.distinguishing_markings,
  c.escaped_at,
  c.status,
  c.fuzz_radius_m,
  st_snaptogrid(
    c.escape_point::geometry,
    (c.fuzz_radius_m / 111320.0)::double precision
  )::geography as approx_area
from cases c
join pets p on p.id = c.pet_id
where c.status = 'open'
  and c.expires_at > now();

-- ---------------------------------------------------------------------------
-- Row-level security
-- ---------------------------------------------------------------------------
-- SKETCH. Needs adversarial review before any live deployment.

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

-- Owner or invited helper.
create or replace function has_case_access(target_case uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from cases c
    where c.id = target_case
      and (
        c.owner_id = auth.uid()
        or exists (
          select 1 from helpers h
          where h.case_id = c.id and h.user_id = auth.uid()
        )
      )
  );
$$;

create policy cases_owner_all on cases
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create policy cases_helper_read on cases
  for select using (has_case_access(id));

create policy places_case_access on search_places
  for all using (has_case_access(case_id)) with check (has_case_access(case_id));

create policy visits_case_access on search_visits
  for all using (has_case_access((select case_id from search_places where id = place_id)))
  with check (has_case_access((select case_id from search_places where id = place_id)));

create policy properties_case_access on properties
  for all using (has_case_access(case_id)) with check (has_case_access(case_id));

create policy stations_case_access on stations
  for all using (has_case_access(case_id)) with check (has_case_access(case_id));

create policy station_events_case_access on station_events
  for all using (has_case_access((select case_id from stations where id = station_id)))
  with check (has_case_access((select case_id from stations where id = station_id)));

-- Sightings: anyone may report on an open case; only the case team may read them,
-- because sighting rows carry the reporter's contact details.
create policy sightings_public_insert on sightings
  for insert with check (
    exists (select 1 from cases c where c.id = case_id and c.status = 'open' and c.expires_at > now())
  );

create policy sightings_case_read on sightings
  for select using (has_case_access(case_id));

create policy sightings_case_write on sightings
  for update using (has_case_access(case_id)) with check (has_case_access(case_id));

-- `pets`, `pet_photos` and `helpers` have RLS enabled but no policies yet. In Postgres
-- that denies all access to ordinary roles, which is the safe direction to be wrong in,
-- but it does mean those tables are unusable until the policies below are written.

-- TODO before any public deployment:
--   * Adversarial review of every policy above.
--   * Policies for pets, pet_photos and helpers (owner-scoped via cases) -- currently
--     deny-all, see the note above.
--   * A pg_cron job to expire cases and purge location data on schedule.
--   * Rate limiting on sightings_public_insert -- currently an open write path.
--   * Decide the fuzz radius. 250m is a placeholder, not a considered figure.
