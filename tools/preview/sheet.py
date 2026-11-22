import sys
from PIL import Image,ImageDraw,ImageFont
out=sys.argv[1]; items=[a.split('=',1) for a in sys.argv[2:]]
ims=[Image.open(p) for p,_ in items]
w,h=ims[0].size; g=50; top=110; cols=int(__import__("os").environ.get("COLS","4"));cols=min(cols,len(ims)); rows=(len(ims)+cols-1)//cols
sheet=Image.new('RGB',(cols*w+(cols+1)*g, rows*(h+top)+g),'#cfd3da'); d=ImageDraw.Draw(sheet)
f=ImageFont.truetype(__import__('os').path.join(__import__('os').path.dirname(__file__),'../../assets/fonts/NotoSans-Bold.ttf'),48)
for i,(im,(_,cap)) in enumerate(zip(ims,items)):
  r,c=divmod(i,cols); x=g+c*(w+g); y=r*(h+top)
  d.text((x,y+40),cap,fill='#1a1a1a',font=f); sheet.paste(im,(x,y+top))
sheet.save(out); print(sheet.size)
