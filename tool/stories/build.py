import json,re
S=json.load(open('e1_q.json'))
ANS={1:'acbc',2:'cdda',3:'bddc',4:'acbd',5:'dadc',6:'acda',7:'baad',8:'bccd',9:'abcd',10:'cacb',11:'cacb',12:'acbb',13:'dbcd',14:'dbca',15:'adcb',16:'cbab',17:'cbbc',18:'badb',19:'bcac',20:'bcab',21:'bacb',22:'dabb',23:'bcad',24:'cbba',25:'dadc',26:'cabc',27:'bbca',28:'acab',29:'adcc',30:'dbca'}
ANS[30]='daca'
TITLE={21:'Katy the Hero'}
FIX={
1:[('in-the','in the'),('kill him.','kill him.”'),('All of the other ammal^Ln theiorest-were very pleased with the rabbit’s clevpriirick.','All of the other animals in the forest were very pleased with the rabbit’s clever trick.')],
2:[('foryour','for your'),('but you it now.','but you found it first. You can have it now.')],
6:[('A ghost can save your','A ghost can save your life!')],
7:[(' rp I Answer the questions.','')],
9:[('starfish*','starfish')],
12:[('Frenhoferwas','Frenhofer was')],
15:[(' FINISH 96','')],
18:[('wheat.*','wheat.'),('want to ** sell','want to sell')],
19:[('.Simon','Simon'),('longtime','long time'),('diet offish','diet of fish')],
20:[('Coronado was id his friends lie to him?','Coronado was sad. Did his friends lie to him?'),('ft the next morning. He looked back at s one more time. The sun reflected light dirt houses. Coronado thought he saw a of gold.','He left the next morning. He looked back at the cities one more time. The sun reflected light off the dirt houses. Coronado thought he saw a flash of gold.')],
22:[('herto','her to')],
23:[('She even Answer the questions.','She even started to like the camp.')],
26:[('Prove to everyone can make decisions by you may at all.','Prove to everyone that you can make your own decisions. If you try to please everyone, you may not please anyone at all.')],
27:[('the bird took the spider home.','At the end of the day, the bird took the spider home.')],
29:[('The sun was inside the flew high and put the sun in the sky. The president was very mad. Raven animals were very happy. At last, they had light—all thinking.','The sun was inside the bag. Raven flew high and put the sun in the sky. The president was very mad, but the other animals were very happy. At last, they had light—all thanks to Raven’s clever thinking.')],
}
DROP=re.compile(r'^(Answer the questions\.|W: \.|\. A f W i|r - -|I \$ i 174|\*starfish.*|\*wheat.*|148.*|Answer the questions\.)$')
out=[]
for s in S:
    u=s['unit'];paras=[p for p in s['paras'] if not DROP.match(p.strip())]
    t='\n'.join(paras)
    for a,b in FIX.get(u,[]):
        assert a in t,(u,a); t=t.replace(a,b)
    paras=[p.strip() for p in t.split('\n') if p.strip()]
    # merge paragraphs that start with lowercase or continue a quote
    m=[]
    for p in paras:
        if m and (p[0].islower() or p.startswith('he told himself')): m[-1]+=' '+p
        else: m.append(p)
    qs=s['qs']
    if u==16:
        q=qs[0]; qs=[{'q':'Where do the boys look for the gold?','o':q['o'][:3]+['In a concert hall']},{'q':'What is NOT true of The Wealth of Adams County?','o':q['o'][4:]}]+qs[1:]
    Q=[]
    for k,q in enumerate(qs[:4]):
        o=[re.sub(r'How ?to','How to',x).replace('Atrip','A trip').strip() for x in q['o']]
        qq=q['q'].replace('Howto','How to').replace('thinkwhile','think while').replace('_______________ ','___ ').strip()
        assert len(o)==4,(u,k,o)
        Q.append({'q':qq,'o':o,'a':'abcd'.index(ANS[u][k])})
    out.append({'id':f'e1|{u}','title':TITLE.get(u,s['title']),'paras':m,'qs':Q})
json.dump(out,open('stories_e1.json','w'),ensure_ascii=False,indent=1)
for s in out: print(s['id'],s['title'],len(s['paras']),sum(len(p.split()) for p in s['paras']))
