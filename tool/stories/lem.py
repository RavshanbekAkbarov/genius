import json,re,warnings
warnings.filterwarnings('ignore')
from nltk.corpus import wordnet as wn
E=json.load(open('/home/claude/genius/assets/data/words.json'))
ess={}
for k,ws in E.items():
    for w in ws: ess.setdefault(w['en'].lower(),w)
IRR={'was':'be','were':'be','is':'be','are':'be','am':'be','been':'be','being':'be','has':'have','had':'have','having':'have','did':'do','does':'do','done':'do','went':'go','gone':'go','men':'man','children':'child','women':'woman','feet':'foot','mice':'mouse','teeth':'tooth','left':'leave','felt':'feel','saw':'see','seen':'see','got':'get','gotten':'get','took':'take','taken':'take','came':'come','gave':'give','given':'give','told':'tell','said':'say','made':'make','found':'find','thought':'think','knew':'know','known':'know','ran':'run','ate':'eat','eaten':'eat','sat':'sit','stood':'stand','began':'begin','begun':'begin','bit':'bite','fell':'fall','fallen':'fall','flew':'fly','grew':'grow','hung':'hang','held':'hold','kept':'keep','led':'lead','lay':'lie','laid':'lay','lost':'lose','met':'meet','paid':'pay','put':'put','read':'read','rode':'ride','rose':'rise','shook':'shake','shot':'shoot','slept':'sleep','sold':'sell','spent':'spend','spoke':'speak','stole':'steal','swam':'swim','taught':'teach','threw':'throw','tore':'tear','understood':'understand','woke':'wake','wore':'wear','won':'win','wrote':'write','written':'write','brought':'bring','bought':'buy','built':'build','caught':'catch','chose':'choose','drew':'draw','drank':'drink','drove':'drive','fed':'feed','fought':'fight','forgot':'forget','heard':'hear','hid':'hide','hidden':'hide','hit':'hit','hurt':'hurt','let':'let','meant':'mean','sent':'send','set':'set','shut':'shut','sang':'sing','struck':'strike','dug':'dig','broke':'break','broken':'break','became':'become','dreamt':'dream','rang':'ring','tried':'try','died':'die','lied':'lie','an':'a','mars':'Mars','clothes':'clothes','woods':'woods','wed':'wed','rose':'rise','ancient':'ancient','news':'news','glasses':'glass','others':'other','puppies':'puppy','berries':'berry','cities':'city','bodies':'body','stories':'story','lenses':'lens','pinches':'pinch','crosses':'cross','vs':'versus','thieves':'thief','shelves':'shelf','downstairs':'downstairs','upstairs':'upstairs','cilia':'cilium'}
CON={"didn’t":"didn't","don’t":"don't"}
NAMES={'isis','osiris','thermopylae','bartelby','gilliam','bertram','adams','argos','minos','pelias','theseus','zeus','yates','mrs','sometimes','always','perhaps','woods','clothes','news','mars','hans','peeves','muggins'}
def lemma(w):
    lw=w.lower().replace('’',"'")
    if lw in NAMES: return 'Mars' if lw=='mars' else lw
    if lw.endswith("'s") and lw not in ("let's","it's","that's","there's","here's","she's","he's","what's"): return lemma(lw[:-2])
    if "'" in lw: return lw
    if lw in IRR: return IRR[lw]
    if lw in ess: return lw
    if lw.endswith('s') and not lw.endswith('ss') and len(lw)>3 and (lw[:-1] in ess or wn.synsets(lw[:-1])) and lw not in ('this','his','its','yes','us','was','has','does','less','always','perhaps','across','bus','famous','nervous','serious','dangerous','various','gas','plus','status','thus','news','mars','chess','christmas','glass','species','series'): return lemma(lw[:-1])
    for pos in ('v','n','a','r'):
        m=wn.morphy(lw,pos)
        if m and m!=lw and (m in ess or True):
            if m in ess: return m
    for pos in ('v','n','a','r'):
        m=wn.morphy(lw,pos)
        if m and m!=lw: return m
    if lw.endswith('er') and wn.morphy(lw,'a') and wn.morphy(lw,'a')!=lw: return wn.morphy(lw,'a')
    return lw
if __name__=='__main__':
    S=json.load(open('stories_e1.json'))
    toks={}
    for s in S:
        for p in s['paras']+[s['title']]:
            for w in re.findall(r"[A-Za-z]+(?:[’'][A-Za-z]+)?",p):
                toks.setdefault(w.lower(),set()).add(s['id'])
    L={}
    for t in toks: L.setdefault(lemma(t),set()).add(t)
    json.dump({k:sorted(v) for k,v in L.items()},open('lemmas_e1.json','w'),indent=0)
    inEss=[k for k in L if k in ess]
    print(len(toks),'forms',len(L),'lemmas',len(inEss),'in essential')
    print(sorted(k for k in L if "'" in k or "’" in k))
