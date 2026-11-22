// usage: node appshots.js outdir route[:scroll] ...   (real app on 8812, hash routes)
const {chromium}=require('playwright');
(async()=>{const out=process.argv[2];const b=await chromium.launch();
for(const spec of process.argv.slice(3)){const [r,sc]=spec.split(':');
const p=await b.newPage({viewport:{width:412,height:892},deviceScaleFactor:2});
await p.goto('http://localhost:8812/#'+r);await p.waitForTimeout(6000);
if(sc){await p.mouse.move(380,400);for(let k=0;k<+sc;k+=300){await p.mouse.wheel(0,300);await p.waitForTimeout(120);}await p.waitForTimeout(1200);}
const name=(r.replace(/[\/?=&]+/g,'_')||'root')+(sc?'-'+sc:'');
await p.screenshot({path:`${out}/${name}.png`});await p.close();}
await b.close();})();
