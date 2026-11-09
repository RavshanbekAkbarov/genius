-- Markaz kitoblarini ilovada ko'rsatish (15 000 so'm, 1-unit bepul namuna).
-- Keyin yashirmoqchi bo'lsangiz, admin panelda "Ilovada" belgisini o'chiring.
update public.books
set published = true
where id in ('aura-beginner', 'aura-foundation', 'aura-pi1a', 'aura-pi2a');
