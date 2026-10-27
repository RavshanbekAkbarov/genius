-- Genius: boshlang'ich sxema (jadvallar, RLS, trigger, RPC funksiyalar).
-- Qayta ishga tushirilsa ham buzilmaydigan qilib yozilgan (if not exists / or replace / drop policy if exists).

-- ============================================================
-- JADVALLAR
-- ============================================================

create table if not exists public.profiles (
  id uuid primary key references auth.users on delete cascade,
  nickname text not null check (char_length(nickname) between 2 and 20),
  avatar text not null default '🦁',
  premium_until date null,
  tg_id bigint unique null,
  tg_username text null,
  created_at timestamptz default now()
);

create table if not exists public.daily_scores (
  user_id uuid references public.profiles on delete cascade,
  day date,
  score int,
  new_words int,
  reviews int,
  sessions int,
  updated_at timestamptz,
  primary key (user_id, day)
);

create table if not exists public.user_state (
  user_id uuid primary key references public.profiles on delete cascade,
  data jsonb not null,
  updated_at timestamptz default now(),
  -- zaxira hajmi cheklovi (~500 KB)
  constraint user_state_size check (octet_length(data::text) < 500000)
);

create table if not exists public.books (
  id text primary key,
  title text not null,
  badge text not null default 'A1',
  color1 text not null default '#FFB347',
  color2 text not null default '#F07B1D',
  units int not null default 20,
  price int not null default 0,
  published boolean not null default false,
  sort int not null default 0
);

create table if not exists public.words (
  book_id text references public.books on delete cascade,
  unit int,
  idx int,
  en text not null,
  uz text not null,
  ipa text not null default '',
  ex text not null default '',
  primary key (book_id, unit, idx)
);

create table if not exists public.purchases (
  user_id uuid references public.profiles on delete cascade,
  book_id text references public.books on delete cascade,
  created_at timestamptz default now(),
  primary key (user_id, book_id)
);

create table if not exists public.payments (
  id bigint generated always as identity primary key,
  user_id uuid references public.profiles on delete cascade,
  kind text not null,
  amount int not null,
  code text unique not null,
  tg_id bigint null,
  receipt_file_id text null,
  status text not null default 'awaiting_receipt'
    check (status in ('awaiting_receipt', 'pending', 'approved', 'rejected')),
  created_at timestamptz default now(),
  decided_at timestamptz null
);

create index if not exists payments_tg_status_idx on public.payments (tg_id, status, created_at desc);
create index if not exists payments_status_idx on public.payments (status, created_at desc);
create index if not exists daily_scores_day_idx on public.daily_scores (day);

create table if not exists public.tg_logins (
  code text primary key,
  tg_id bigint null,
  tg_username text null,
  confirmed boolean not null default false,
  created_at timestamptz default now()
);

create table if not exists public.admins (
  user_id uuid primary key references auth.users on delete cascade
);

-- ============================================================
-- YORDAMCHI FUNKSIYALAR
-- ============================================================

-- Joriy foydalanuvchi adminmi?
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

-- Kitob so'zlarini o'qish mumkinmi? (nashr qilingan va bepul yoki sotib olingan)
-- security definer: anon rolida purchases jadvaliga ruxsat bo'lmasa ham ishlaydi
create or replace function public.can_read_book(p_book text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.books b
    where b.id = p_book
      and b.published
      and (
        b.price = 0
        or exists (
          select 1 from public.purchases p
          where p.user_id = auth.uid() and p.book_id = b.id
        )
      )
  );
$$;

-- Tasodifiy [a-z0-9] kod (gen_random_uuid kuchli tasodifiylik beradi, kengaytma shart emas)
create or replace function public._rand_code(n int)
returns text
language plpgsql
volatile
set search_path = public
as $$
declare
  alphabet constant text := 'abcdefghijklmnopqrstuvwxyz0123456789';
  b bytea;
  r text := '';
  i int;
begin
  while char_length(r) < n loop
    b := uuid_send(gen_random_uuid());
    for i in 0..15 loop
      exit when char_length(r) >= n;
      -- 6 va 8-baytlarda uuid versiya bitlari bor, ularni tashlab ketamiz
      continue when i in (6, 8);
      r := r || substr(alphabet, (get_byte(b, i) % 36) + 1, 1);
    end loop;
  end loop;
  return r;
end;
$$;

-- Yangi foydalanuvchi uchun profil yaratish
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, nickname)
  values (new.id, 'Genius_' || lpad((floor(random() * 10000))::int::text, 4, '0'))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================
-- RLS
-- ============================================================

alter table public.profiles enable row level security;
alter table public.daily_scores enable row level security;
alter table public.user_state enable row level security;
alter table public.books enable row level security;
alter table public.words enable row level security;
alter table public.purchases enable row level security;
alter table public.payments enable row level security;
alter table public.tg_logins enable row level security;
alter table public.admins enable row level security;

-- profiles
drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles
  for select to authenticated using (id = (select auth.uid()));
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));
drop policy if exists profiles_admin_select on public.profiles;
create policy profiles_admin_select on public.profiles
  for select to authenticated using (public.is_admin());

-- daily_scores (oddiy foydalanuvchiga to'g'ridan-to'g'ri ruxsat yo'q, faqat RPC)
drop policy if exists daily_scores_admin_select on public.daily_scores;
create policy daily_scores_admin_select on public.daily_scores
  for select to authenticated using (public.is_admin());

-- user_state
drop policy if exists user_state_select_own on public.user_state;
create policy user_state_select_own on public.user_state
  for select to authenticated using (user_id = (select auth.uid()));
drop policy if exists user_state_insert_own on public.user_state;
create policy user_state_insert_own on public.user_state
  for insert to authenticated with check (user_id = (select auth.uid()));
drop policy if exists user_state_update_own on public.user_state;
create policy user_state_update_own on public.user_state
  for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- books
drop policy if exists books_select_published on public.books;
create policy books_select_published on public.books
  for select to anon, authenticated using (published);
drop policy if exists books_admin_all on public.books;
create policy books_admin_all on public.books
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- words: kitob nashr qilingan va (bepul yoki sotib olingan)
drop policy if exists words_select_allowed on public.words;
create policy words_select_allowed on public.words
  for select to anon, authenticated using (public.can_read_book(book_id));
drop policy if exists words_admin_all on public.words;
create policy words_admin_all on public.words
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- purchases
drop policy if exists purchases_select_own on public.purchases;
create policy purchases_select_own on public.purchases
  for select to authenticated using (user_id = (select auth.uid()));
drop policy if exists purchases_admin_all on public.purchases;
create policy purchases_admin_all on public.purchases
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- payments
drop policy if exists payments_select_own on public.payments;
create policy payments_select_own on public.payments
  for select to authenticated using (user_id = (select auth.uid()));
drop policy if exists payments_admin_all on public.payments;
create policy payments_admin_all on public.payments
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- tg_logins: mijozga hech qanday ruxsat yo'q (faqat service role)

-- admins: o'z qatorini ko'rish
drop policy if exists admins_select_own on public.admins;
create policy admins_select_own on public.admins
  for select to authenticated using (user_id = (select auth.uid()));

-- ============================================================
-- GRANTLAR (Supabase standart grantlariga suyanmasdan aniq beramiz)
-- ============================================================

revoke all on table
  public.profiles, public.daily_scores, public.user_state, public.books,
  public.words, public.purchases, public.payments, public.tg_logins, public.admins
from anon, authenticated;

grant all on table
  public.profiles, public.daily_scores, public.user_state, public.books,
  public.words, public.purchases, public.payments, public.tg_logins, public.admins
to service_role;
grant usage, select on all sequences in schema public to service_role;

grant select on public.profiles to authenticated;
-- faqat nickname va avatar ni o'zgartirish mumkin
grant update (nickname, avatar) on public.profiles to authenticated;

grant select on public.daily_scores to authenticated;

grant select, insert, update on public.user_state to authenticated;

grant select on public.books to anon, authenticated;
grant insert, update, delete on public.books to authenticated;

grant select on public.words to anon, authenticated;
grant insert, update, delete on public.words to authenticated;

grant select, insert, update, delete on public.purchases to authenticated;
grant select, insert, update, delete on public.payments to authenticated;

grant select on public.admins to authenticated;

-- ============================================================
-- RPC FUNKSIYALAR
-- ============================================================

-- To'lov kodi yaratish ('premium' yoki 'book:<id>')
create or replace function public.create_pay_code(p_kind text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_amount int;
  v_book text;
  v_code text;
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  if p_kind = 'premium' then
    v_amount := 10000;
  elsif p_kind like 'book:%' then
    v_book := substr(p_kind, 6);
    select price into v_amount from public.books where id = v_book and published;
    if not found or v_amount is null or v_amount <= 0 then
      raise exception 'bad_book';
    end if;
    if exists (select 1 from public.purchases where user_id = v_uid and book_id = v_book) then
      raise exception 'already_purchased';
    end if;
  else
    raise exception 'bad_kind';
  end if;

  loop
    v_code := public._rand_code(12);
    begin
      insert into public.payments (user_id, kind, amount, code)
      values (v_uid, p_kind, v_amount, v_code);
      exit;
    exception when unique_violation then
      -- kod takrorlandi (juda kam ehtimol), qaytadan
    end;
  end loop;

  return v_code;
end;
$$;

-- Kunlik natijani yuborish (anti-cheat bilan)
create or replace function public.submit_day(
  p_day date,
  p_score int,
  p_new_words int,
  p_reviews int,
  p_sessions int
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_today date := (now() at time zone 'Asia/Tashkent')::date;
  r public.daily_scores%rowtype;
  v_minutes numeric;
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  if p_day is null or (p_day <> v_today and p_day <> v_today - 1) then
    return json_build_object('ok', false, 'reason', 'day');
  end if;

  if p_score is null or p_new_words is null or p_reviews is null or p_sessions is null
     or p_score < 0 or p_new_words < 0 or p_reviews < 0 or p_sessions < 0
     or p_score > 400 or p_new_words > 300 or p_reviews > 600 or p_sessions > 60 then
    return json_build_object('ok', false, 'reason', 'limit');
  end if;

  select * into r from public.daily_scores
  where user_id = v_uid and day = p_day
  for update;

  if found then
    v_minutes := greatest(extract(epoch from (now() - coalesce(r.updated_at, now()))) / 60.0, 0);
    if p_score - coalesce(r.score, 0) > 60 * (v_minutes + 1) then
      return json_build_object('ok', false, 'reason', 'rate');
    end if;
    update public.daily_scores set
      score = greatest(coalesce(score, 0), p_score),
      new_words = greatest(coalesce(new_words, 0), p_new_words),
      reviews = greatest(coalesce(reviews, 0), p_reviews),
      sessions = greatest(coalesce(sessions, 0), p_sessions),
      updated_at = now()
    where user_id = v_uid and day = p_day;
  else
    insert into public.daily_scores as d (user_id, day, score, new_words, reviews, sessions, updated_at)
    values (v_uid, p_day, p_score, p_new_words, p_reviews, p_sessions, now())
    on conflict (user_id, day) do update set
      score = greatest(coalesce(d.score, 0), excluded.score),
      new_words = greatest(coalesce(d.new_words, 0), excluded.new_words),
      reviews = greatest(coalesce(d.reviews, 0), excluded.reviews),
      sessions = greatest(coalesce(d.sessions, 0), excluded.sessions),
      updated_at = now();
  end if;

  return json_build_object('ok', true, 'reason', null);
end;
$$;

-- Admin: qo'lda Premium berish (p_days kun). p_days = 0 bo'lsa Premium olib tashlanadi.
create or replace function public.admin_grant_premium(p_user uuid, p_days int)
returns date
language plpgsql
security definer
set search_path = public
as $$
declare
  v_today date := (now() at time zone 'Asia/Tashkent')::date;
  v_until date;
begin
  if not public.is_admin() then
    raise exception 'forbidden';
  end if;
  if p_days is null or p_days < 0 or p_days > 3650 then
    raise exception 'bad_days';
  end if;
  if p_days = 0 then
    update public.profiles set premium_until = null where id = p_user;
  else
    update public.profiles
    set premium_until = greatest(coalesce(premium_until, v_today), v_today) + p_days
    where id = p_user
    returning premium_until into v_until;
  end if;
  if not found then
    raise exception 'user_not_found';
  end if;
  return v_until;
end;
$$;

-- To'lovni tasdiqlash / rad etish (faqat edge funksiyalar, service role orqali chaqiradi).
-- Faqat 'pending' holatdagi to'lovga ta'sir qiladi, shuning uchun ikki marta bosish xavfsiz.
create or replace function public.decide_payment(p_id bigint, p_approve boolean)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_today date := (now() at time zone 'Asia/Tashkent')::date;
  p public.payments%rowtype;
  v_until date;
  v_title text;
  v_tg bigint;
  v_nick text;
begin
  update public.payments
  set status = case when p_approve then 'approved' else 'rejected' end,
      decided_at = now()
  where id = p_id and status = 'pending'
  returning * into p;

  if not found then
    return json_build_object('ok', false, 'status', (select status from public.payments where id = p_id));
  end if;

  if p.kind like 'book:%' then
    select title into v_title from public.books where id = substr(p.kind, 6);
  end if;

  if p_approve then
    if p.kind = 'premium' then
      update public.profiles
      set premium_until = greatest(coalesce(premium_until, v_today), v_today) + 30
      where id = p.user_id
      returning premium_until into v_until;
    elsif p.kind like 'book:%' then
      insert into public.purchases (user_id, book_id)
      values (p.user_id, substr(p.kind, 6))
      on conflict do nothing;
    end if;
  end if;

  select coalesce(p.tg_id, pr.tg_id), pr.nickname into v_tg, v_nick
  from public.profiles pr where pr.id = p.user_id;

  return json_build_object(
    'ok', true,
    'approved', p_approve,
    'id', p.id,
    'user_id', p.user_id,
    'kind', p.kind,
    'amount', p.amount,
    'tg_id', v_tg,
    'nickname', v_nick,
    'premium_until', v_until,
    'book_title', v_title
  );
end;
$$;

-- Funksiya ruxsatlari: standart PUBLIC ruxsatini olib tashlaymiz
revoke all on function public.is_admin() from public, anon;
revoke all on function public.can_read_book(text) from public;
revoke all on function public._rand_code(int) from public, anon, authenticated;
revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.create_pay_code(text) from public, anon;
revoke all on function public.submit_day(date, int, int, int, int) from public, anon;
revoke all on function public.admin_grant_premium(uuid, int) from public, anon;
revoke all on function public.decide_payment(bigint, boolean) from public, anon, authenticated;

grant execute on function public.is_admin() to authenticated, service_role;
grant execute on function public.can_read_book(text) to anon, authenticated, service_role;
grant execute on function public.create_pay_code(text) to authenticated;
grant execute on function public.submit_day(date, int, int, int, int) to authenticated;
grant execute on function public.admin_grant_premium(uuid, int) to authenticated;
grant execute on function public.decide_payment(bigint, boolean) to service_role;
grant execute on function public._rand_code(int) to service_role;
