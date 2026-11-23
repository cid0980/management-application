const {chromium}=require('playwright');
(async()=>{const out=process.argv[2];const route=process.argv[3]||'/service';const n=+(process.argv[4]||14);
const b=await chromium.launch();
const p=await b.newPage({viewport:{width:412,height:892},deviceScaleFactor:1});
await p.goto('http://localhost:8812/#'+route);await p.waitForTimeout(6500);
await p.evaluate(()=>{const e=document.querySelector('flt-semantics-placeholder'); if(e) e.click();});
await p.waitForTimeout(800);
async function tap(name){const el=p.locator('flt-semantics[role="button"]',{hasText:name}).last(); if(await el.count()===0){console.log('missing',name);return false;} await el.click({force:true}); return true;}
// the ? button
const q=p.locator('flt-semantics[role="button"]',{hasText:'Tour of this page'});
if(await q.count()>0) await q.last().click({force:true}); else console.log('no ? button');
await p.waitForTimeout(3500);
for(let i=1;i<=n;i++){
  await p.screenshot({path:`${out}/s${String(i).padStart(2,'0')}.png`});
  const ok=await tap(i===n?'Done':'Next'); if(!ok) break;
  await p.waitForTimeout(4200);
}
await p.screenshot({path:`${out}/end.png`});
await b.close();})();
