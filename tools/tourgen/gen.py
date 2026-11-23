import json, re, sys
sys.path.insert(0, 'tools/tourgen')
from chapters import CH
def cap(x): return x[0].upper()+x[1:]
strings = {}  # key -> (en,ta,hi)
dart_ch = []
for c in CH:
    cid = cap(c['id'])
    strings[f'tourCh{cid}Title'] = c['title']
    strings[f'tourCh{cid}Blurb'] = c['blurb']
    steps=[]
    for i,st in enumerate(c['steps'],1):
        kt=f'tour{cid}{i}T'; kb=f'tour{cid}{i}B'
        strings[kt]=st['t']; strings[kb]=st['b']
        args=[repr(st['target']).replace("None","null") if st['target'] is None else "'%s'"%st['target'], f'l.{kt}', f'l.{kb}']
        named=[]
        if st['route']: named.append(f"route: '{st['route']}'")
        if st['act']: named.append(f"act: (d) async {{ {st['act']} }}")
        steps.append('      TourStep(' + ', '.join(args + named) + '),')
    pages=', '.join("'%s'"%p for p in c['pages'])
    dart_ch.append(f"""  TourChapter(
    id: '{c['id']}',
    icon: {c['icon']},
    title: l.tourCh{cid}Title,
    blurb: l.tourCh{cid}Blurb,
    pages: const [{pages}],
    steps: [
{chr(10).join(steps)}
    ],
  ),""")
# extra UI strings
strings['tourChAroundTitle']=("Getting around","பக்கங்களைச் சுற்றி","ऐप में घूमना")
strings['tourChAroundBlurb']=("What each page is for and where to tap","ஒவ்வொரு பக்கமும் எதற்கு, எங்கே தட்டுவது","हर पेज किस काम का है और कहाँ दबाना है")
strings['tourThisPage']=("Tour of this page","இந்தப் பக்கத்தின் சுற்றுப்பயணம்","इस पेज का टूर")
strings['tourMenuTitle']=("App tours","ஆப் சுற்றுப்பயணங்கள்","ऐप टूर")
strings['tourPractice']=("Practice data: nothing here is saved","பயிற்சித் தகவல்: இங்கே எதுவும் சேமிக்கப்படாது","अभ्यास डेटा: यहाँ कुछ भी सेव नहीं होता")
strings['tourFilling']=("The tour is filling this in…","சுற்றுப்பயணம் இதை நிரப்புகிறது…","टूर इसे भर रहा है…")
for li,lang in enumerate(('en','ta','hi')):
    p=f'lib/l10n/app_{lang}.arb'; s=open(p).read()
    i=s.index('"imeiScanSecond"'); ls=s.rfind('\n',0,i)+1
    e=''
    for k,v in strings.items():
        if f'"{k}"' in s: continue
        e+='  "%s": %s,\n'%(k,json.dumps(v[li],ensure_ascii=False))
        if lang=='en': e+='  "@%s": {\n    "description": "App tour"\n  },\n'%k
    s=s[:ls]+e+s[ls:]; json.loads(s); open(p,'w').write(s)
open('tools/tourgen/chapters.dart.part','w').write('\n'.join(dart_ch))
print(len(strings),'strings')
