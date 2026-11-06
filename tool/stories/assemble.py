import json,re,sys
sys.path.insert(0,'.')
import warnings;warnings.filterwarnings('ignore')
from lem import lemma
E=json.load(open('/home/claude/genius/assets/data/words.json'))
ess={}
for ws in E.values():
  for w in ws: ess.setdefault(w['en'].lower(),w)
# CMU -> IPA (American, as in words.json)
V={'AA':'ɑ','AE':'æ','AH':'ʌ','AO':'ɔ','AW':'aʊ','AY':'aɪ','EH':'e','ER':'ɜr','EY':'eɪ','IH':'ɪ','IY':'i','OW':'oʊ','OY':'ɔɪ','UH':'ʊ','UW':'u'}
C={'B':'b','CH':'tʃ','D':'d','DH':'ð','F':'f','G':'ɡ','HH':'h','JH':'dʒ','K':'k','L':'l','M':'m','N':'n','NG':'ŋ','P':'p','R':'r','S':'s','SH':'ʃ','T':'t','TH':'θ','V':'v','W':'w','Y':'j','Z':'z','ZH':'ʒ'}
cmu={}
for l in open('cmudict.dict'):
    p=l.split('#')[0].split()
    if not p or '(' in p[0]: continue
    cmu[p[0]]=p[1:]
def ipa(w):
    ph=cmu.get(w)
    if not ph: return ''
    out=[];nv=sum(1 for x in ph if x[-1].isdigit())
    for x in ph:
        if x[-1].isdigit():
            b,s=x[:-1],x[-1]
            v=V[b]
            if b=='AH' and s=='0': v='ə'
            if b=='ER' and s=='0': v='ər'
            if b=='IY' and s=='0': v='i'
            if s=='1' and nv>1:
                # put stress before onset consonant
                j=len(out)
                while j>0 and out[j-1] in C.values() and not (j-2>=0 and out[j-2] in C.values() and False): j-=1; break
                out.insert(j,'ˈ')
            out.append(v)
        else: out.append(C[x])
    return '/'+''.join(out)+'/'
D={}
for f in ['dict_a.txt','dict_b.txt']:
  for line in open(f):
    line=line.rstrip('\n')
    if not line: continue
    k,uz,syn=line.split('|')
    e=ess.get(k.lower())
    u=uz or (e['uz'] if e else '')
    assert u,k
    D[k]=[u,[s.strip() for s in syn.split(',') if s.strip()][:4],(e['ipa'] if e else ipa(k.lower().replace("'",'')))]
S=json.load(open('stories_e1.json'))
forms={}
for s in S:
    for p in s['paras']+[s['title']]:
        for w in re.findall(r"[A-Za-z]+(?:[’'][A-Za-z]+)?",p):
            k=w.lower().replace('’',"'"); lm=lemma(w)
            assert lm in D,(w,lm)
            if lm!=k: forms[k]=lm
out={'stories':{s['id']:{'title':s['title'],'paras':s['paras'],'qs':s['qs']} for s in S},'dict':D,'forms':forms}
json.dump(out,open('/home/claude/genius/assets/data/stories.json','w'),ensure_ascii=False,separators=(',',':'))
print(len(D),len(forms))
print({k:D[k] for k in ['clever','well','jump','hedgehog' if 'hedgehog' in D else 'lion','because']})
