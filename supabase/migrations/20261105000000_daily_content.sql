-- Kunning so'zi va motivatsion iqtiboslar: admin paneldan qo'shiladi va tahrirlanadi.
-- Qayta ishga tushirilsa ham buzilmaydi.

create table if not exists public.quotes (
  id bigint generated always as identity primary key,
  en text not null,
  uz text not null,
  author text not null,
  active boolean not null default true,
  sort int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.daily_words (
  day date primary key,
  en text not null,
  uz text not null,
  ipa text not null default '',
  ex text not null default ''
);

-- Aniq grantlar ("Automatically expose new tables" o'chiq bo'lsa ham ishlaydi).
revoke all on table public.quotes, public.daily_words from anon, authenticated;
grant all on table public.quotes, public.daily_words to service_role;
grant usage, select on sequence public.quotes_id_seq to service_role, authenticated;
grant select on public.quotes, public.daily_words to anon, authenticated;
grant insert, update, delete on public.quotes, public.daily_words to authenticated;

alter table public.quotes enable row level security;
alter table public.daily_words enable row level security;

drop policy if exists quotes_select_active on public.quotes;
create policy quotes_select_active on public.quotes
  for select to anon, authenticated using (active or public.is_admin());
drop policy if exists quotes_admin_all on public.quotes;
create policy quotes_admin_all on public.quotes
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists daily_words_select_all on public.daily_words;
create policy daily_words_select_all on public.daily_words
  for select to anon, authenticated using (true);
drop policy if exists daily_words_admin_all on public.daily_words;
create policy daily_words_admin_all on public.daily_words
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Ilovadagi tayyor iqtiboslar (jadval bo'sh bo'lsa bir marta qo'shiladi), keyin admin paneldan tahrirlanadi.
insert into public.quotes (en, uz, author, sort)
select v.en, v.uz, v.author, v.sort from (values
  ('Education is the most powerful weapon which you can use to change the world.', 'Ta''lim dunyoni o''zgartirish uchun ishlatishingiz mumkin bo''lgan eng kuchli quroldir.', 'Nelson Mandela', 0),
  ('Imagination is more important than knowledge.', 'Tasavvur bilimdan muhimroq.', 'Albert Einstein', 1),
  ('Life is like riding a bicycle. To keep your balance you must keep moving.', 'Hayot velosiped haydashga o''xshaydi. Muvozanatni saqlash uchun to''xtamay harakatlanish kerak.', 'Albert Einstein', 2),
  ('Genius is one percent inspiration, ninety-nine percent perspiration.', 'Daho bir foiz ilhom va to''qson to''qqiz foiz mehnatdir.', 'Thomas Edison', 3),
  ('If I have seen further, it is by standing on the shoulders of giants.', 'Agar men uzoqroqni ko''rgan bo''lsam, bu gigantlarning yelkasida turganim uchundir.', 'Isaac Newton', 4),
  ('The limits of my language mean the limits of my world.', 'Tilimning chegaralari dunyoimning chegaralaridir.', 'Ludwig Wittgenstein', 5),
  ('We are what we repeatedly do. Excellence, then, is not an act, but a habit.', 'Biz takror-takror qiladigan ishimizmiz. Demak, mukammallik bir martalik ish emas, odatdir.', 'Will Durant', 6),
  ('The only way to do great work is to love what you do.', 'Buyuk ish qilishning yagona yo''li qilayotgan ishingizni sevishdir.', 'Steve Jobs', 7),
  ('Your time is limited, so don''t waste it living someone else''s life.', 'Vaqtingiz cheklangan, uni boshqa birovning hayotini yashab o''tkazmang.', 'Steve Jobs', 8),
  ('Stay hungry. Stay foolish.', 'Doim och bo''ling. Doim sodda bo''ling.', 'Steve Jobs', 9),
  ('Education is our passport to the future, for tomorrow belongs to the people who prepare for it today.', 'Ta''lim kelajakka pasportimiz, chunki ertangi kun unga bugun tayyorlanayotganlarniki.', 'Malcolm X', 10),
  ('I''ve failed over and over and over again in my life. And that is why I succeed.', 'Hayotimda qayta-qayta yutqazganman. Aynan shuning uchun muvaffaqiyatga erishaman.', 'Michael Jordan', 11),
  ('Leadership and learning are indispensable to each other.', 'Yetakchilik va o''rganish bir-birisiz bo''lmaydi.', 'John F. Kennedy', 12),
  ('The roots of education are bitter, but the fruit is sweet.', 'Ilmning ildizi achchiq, ammo mevasi shirin.', 'Aristotel', 13),
  ('While we teach, we learn.', 'Biz o''rgatayotib o''rganamiz.', 'Seneka', 14),
  ('I learned very early the difference between knowing the name of something and knowing something.', 'Men juda erta bir narsaning nomini bilish bilan o''sha narsani bilish orasidagi farqni tushunganman.', 'Richard Feynman', 15),
  ('A journey of a thousand miles begins with a single step.', 'Ming chaqirimlik yo''l bitta qadamdan boshlanadi.', 'Lao Szi', 16),
  ('Fall seven times, stand up eight.', 'Yetti marta yiqilsang, sakkiz marta tur.', 'Yapon maqoli', 17)
) as v(en, uz, author, sort)
where not exists (select 1 from public.quotes);
