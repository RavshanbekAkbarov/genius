"""Gaplar tarjimasini (tr_eN.txt) assets/data/stories.json ga qo'shadi.

tr_eN.txt: "## e1|1" sarlavha, keyin har bir gapning o'zbekchasi alohida qatorda,
matndagi tartibda. Gaplar soni ilova bo'ladigan qoida bilan tekshiriladi
(lib/data/stories.dart, Story.spans).
Ishga tushirish: python3 tool/stories/merge_tr.py
"""
import glob, json, os, re, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(ROOT, '..', '..', 'assets', 'data', 'stories.json')
ENDS = re.compile(r'[.!?]["”’]?\s+(?=[“"‘A-Z0-9])')
# “Why?” Liz asked. - qo'shtirnoqdan keyin "kim dedi" kelsa, bu bitta gap.
ABBR = re.compile(r'\b(?:Mr|Mrs|Ms|Dr|Mt|St|Jr|Sr)\.$')
SPEECH = re.compile(r"^(?:[\w’']+\s+){0,2}(?:said|asked|replied|answered|thought|shouted|cried|yelled|screamed|whispered|told|explained|added|exclaimed|called|laughed|continued|agreed|wondered|says|asks)\b")


def split(p):
    out, a = [], 0
    for m in ENDS.finditer(p):
        if '”' in m.group() and SPEECH.match(p[m.end():]): continue
        if ABBR.search(p[:m.start() + 1]): continue
        out.append(p[a:m.end()].strip()); a = m.end()
    if p[a:].strip(): out.append(p[a:].strip())
    return out


d = json.load(open(OUT))
bad = 0
for f in sorted(glob.glob(os.path.join(ROOT, 'tr_e*.txt'))):
    cur, tr = None, {}
    for line in open(f, encoding='utf-8'):
        line = line.strip()
        if not line: continue
        if line.startswith('## '): cur = line[3:]; tr[cur] = []; continue
        tr[cur].append(line)
    for k, v in tr.items():
        s = d['stories'][k]
        want = sum(len(split(p)) for p in s['paras'])
        if len(v) != want:
            print(f'{k}: {len(v)} ta tarjima, {want} ta gap'); bad += 1; continue
        s['tr'] = v
if bad: sys.exit(1)
json.dump(d, open(OUT, 'w'), ensure_ascii=False, separators=(',', ':'))
print('ok', sum(1 for s in d['stories'].values() if s.get('tr')))
