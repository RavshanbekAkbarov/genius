-- Pullik markaz kitoblarining 1-uniti hamma uchun bepul namuna.
-- Qolgan unitlar avvalgidek faqat kitob bepul bo'lsa yoki sotib olingan bo'lsa o'qiladi.
create or replace function public.can_read_unit(p_book text, p_unit int)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.can_read_book(p_book)
    or (p_unit = 1 and exists (select 1 from public.books b where b.id = p_book and b.published));
$$;

drop policy if exists words_select_allowed on public.words;
create policy words_select_allowed on public.words
  for select to anon, authenticated using (public.can_read_unit(book_id, unit));

revoke all on function public.can_read_unit(text, int) from public;
grant execute on function public.can_read_unit(text, int) to anon, authenticated, service_role;
