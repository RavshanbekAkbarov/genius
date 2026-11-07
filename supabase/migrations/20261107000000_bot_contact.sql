-- Bot: foydalanuvchi avval Telegram profilini (ism) ulashadi, so'ng to'lov va ilova haqida ma'lumot.
-- Qayta ishga tushirilsa ham buzilmaydi.

-- Botga yozgan har bir Telegram foydalanuvchisi: ulashgan ismi va raqami.
create table if not exists public.tg_users (
  tg_id bigint primary key,
  first_name text null,
  last_name text null,
  phone text null,
  tg_username text null,
  shared_at timestamptz null,          -- ism ulashilgan vaqt (null = hali ulashmagan)
  pending_start text null,             -- ulashishdan oldin bosilgan /start parametri (login_..., pay_...)
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Faqat server (bot) o'qiydi va yozadi.
alter table public.tg_users enable row level security;
revoke all on table public.tg_users from anon, authenticated;
grant all on table public.tg_users to service_role;

-- To'lov kodi yaratish berilgan foydalanuvchi uchun (bot ichidan xarid qilinganda, faqat server chaqiradi).
create or replace function public.create_pay_code_for(p_uid uuid, p_kind text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_amount int;
  v_book text;
  v_code text;
begin
  if p_uid is null then
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
    if exists (select 1 from public.purchases where user_id = p_uid and book_id = v_book) then
      raise exception 'already_purchased';
    end if;
  else
    raise exception 'bad_kind';
  end if;

  loop
    v_code := public._rand_code(12);
    begin
      insert into public.payments (user_id, kind, amount, code)
      values (p_uid, p_kind, v_amount, v_code);
      exit;
    exception when unique_violation then
      -- kod takrorlandi (juda kam ehtimol), qaytadan
    end;
  end loop;

  return v_code;
end;
$$;

-- Ilova chaqiradigan eski funksiya endi yuqoridagini o'z foydalanuvchisi bilan chaqiradi.
create or replace function public.create_pay_code(p_kind text)
returns text
language plpgsql
security definer
set search_path = public
as $$
begin
  return public.create_pay_code_for(auth.uid(), p_kind);
end;
$$;

revoke all on function public.create_pay_code_for(uuid, text) from public, anon, authenticated;
grant execute on function public.create_pay_code_for(uuid, text) to service_role;
revoke all on function public.create_pay_code(text) from public, anon;
grant execute on function public.create_pay_code(text) to authenticated;
