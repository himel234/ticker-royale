-- Ticker Royale v2 database. Supabase → SQL Editor → paste → Run.
create extension if not exists pgcrypto;

-- One row per match (Battle Royale, Spin & Go, 1v1 Duel)
create table if not exists matches (
  id          uuid primary key default gen_random_uuid(),
  mode        text        not null,             -- 'br' | 'spin' | 'duel'
  seats       int         not null,
  start_at    timestamptz not null,             -- queue closes / trading starts
  seed        bigint      not null,             -- makes bots identical for every player
  rewarded    boolean     not null default true,-- false once the 10 daily prize BRs are used
  spin_prize  int,                              -- Spin & Go prize, decided at creation
  day_key     text        not null,             -- UTC day 'YYYY-MM-DD'
  created_at  timestamptz not null default now()
);
create index if not exists matches_open on matches (mode, start_at);

-- Humans in each match (bots are generated in the browser from the seed)
create table if not exists match_players (
  match_id    uuid   not null references matches(id) on delete cascade,
  player_id   text   not null,
  name        text   not null,
  wallet      text,
  equity      numeric not null default 1000,
  alive       boolean not null default true,
  out_at      int,
  updated_at  timestamptz not null default now(),
  primary key (match_id, player_id)
);

-- Token ledger: every finished game, quest, streak and referral.
create table if not exists rewards (
  id          bigserial primary key,
  player_id   text    not null,
  name        text,
  wallet      text,
  kind        text    not null,   -- br | spin | duel | quest | referral
  ref         text    not null,   -- match id, 'day:quest', or referral key
  amount      numeric not null default 0,
  rank        int,
  players     int,
  day_key     text    not null,
  paid        boolean not null default false,  -- set true after you airdrop it
  created_at  timestamptz not null default now(),
  unique (player_id, kind, ref)   -- can't be paid twice for the same thing
);
create index if not exists rewards_player on rewards (player_id);

alter table matches       enable row level security;
alter table match_players enable row level security;
alter table rewards       enable row level security;

-- Testnet-level open access for the anon key.
create policy "m read"   on matches       for select using (true);
create policy "m insert" on matches       for insert with check (true);
create policy "p read"   on match_players for select using (true);
create policy "p insert" on match_players for insert with check (true);
create policy "p update" on match_players for update using (true);
create policy "p delete" on match_players for delete using (true);
create policy "r read"   on rewards       for select using (true);
create policy "r insert" on rewards       for insert with check (true);

-- =====================================================================
-- AIRDROP LIST: tokens owed per wallet. Run, then Export → CSV.
-- (The app's Ranks tab also has this as a Copy CSV button at ?admin=1)
-- =====================================================================
-- with w as (
--   select player_id, max(wallet) as wallet from rewards where wallet is not null group by player_id
-- )
-- select w.wallet, sum(r.amount) as tokens
-- from rewards r join w using (player_id)
-- where not r.paid
-- group by w.wallet
-- having sum(r.amount) > 0
-- order by tokens desc;

-- After you send the airdrop, mark everything as paid so it isn't paid twice:
-- update rewards set paid = true where not paid and created_at < '<time you ran the list>';
