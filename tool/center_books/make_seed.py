"""Markaz kitoblari (Beginner, Foundation, Pre-IELTS 1A/2A) so'zlarini Supabase migratsiyasiga aylantiradi.

Ishlatish:  python3 tool/center_books/make_seed.py
Natija:     supabase/migrations/20261107000000_center_books.sql

Kitoblar yashirin (published=false) va narxsiz qo'shiladi: narxni qo'yib, "Ilovada" belgisini
admin paneldan yoqasiz. Qayta ishga tushirilsa admin o'zgartirgan narsalar ustidan yozilmaydi.
"""
import json
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'supabase', 'migrations', '20261107000000_center_books.sql')

# (fayl, kitob id, badge, nom, rang1, rang2, tartib)
BOOKS = [
    ('beginner.json', 'aura-beginner', 'B', 'Beginner', '#FFB347', '#F07B1D', 10),
    ('foundation.json', 'aura-foundation', 'F', 'Foundation', '#FF7A7A', '#D9363E', 11),
    ('pre-ielts-1a.json', 'aura-pi1a', '1A', 'Pre-IELTS 1A', '#5CC8FF', '#1E7FC9', 12),
    ('pre-ielts-2a.json', 'aura-pi2a', '2A', 'Pre-IELTS 2A', '#8C7CFF', '#4B3BC4', 13),
]


def q(s):
    return "'" + str(s).replace("'", "''") + "'"


def main():
    lines = [
        '-- Markaz kitoblari: unit bo\'yicha tanlangan so\'zlar va so\'z birikmalari.',
        '-- tool/center_books/make_seed.py yaratgan; qo\'lda tahrirlamang.',
        '-- Kitoblar yashirin qo\'shiladi: narx va "Ilovada" belgisi admin paneldan qo\'yiladi.',
        '',
    ]
    for fname, bid, badge, title, c1, c2, sort in BOOKS:
        data = json.load(open(os.path.join(HERE, fname), encoding='utf-8'))
        units = sorted(int(re.search(r'\|(\d+)$', k).group(1)) for k in data)
        lines.append(
            'insert into public.books (id, title, badge, color1, color2, units, price, published, sort) values '
            f'({q(bid)}, {q(title)}, {q(badge)}, {q(c1)}, {q(c2)}, {max(units)}, 0, false, {sort}) '
            'on conflict (id) do nothing;')
        rows = []
        for key, items in data.items():
            unit = int(key.split('|')[1])
            for idx, w in enumerate(items):
                rows.append(f"({q(bid)}, {unit}, {idx}, {q(w['en'])}, {q(w['uz'])}, {q(w['ipa'])}, '')")
        lines.append('insert into public.words (book_id, unit, idx, en, uz, ipa, ex) values')
        lines.append(',\n'.join(rows))
        lines.append('on conflict (book_id, unit, idx) do nothing;')
        lines.append('')
    with open(OUT, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    print('yozildi:', os.path.normpath(OUT))


if __name__ == '__main__':
    main()
