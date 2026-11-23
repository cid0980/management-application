const {chromium}=require('playwright');
(async()=>{const out=process.argv[2];const routes=(process.argv[3]||'/sales,/enquiries,/admin/tasks,/admin/staff').split(',');
const b=await chromium.launch();
for(const route of routes){
const name=route.replace(/\//g,'_');
const p=await b.newPage({viewport:{width:412,height:892},deviceScaleFactor:1});
await p.goto('http://localhost:8812/#'+route);await p.waitForTimeout(6000);
await p.evaluate(()=>{const e=document.querySelector('flt-semantics-placeholder'); if(e) e.click();});
await p.waitForTimeout(700);
const q=p.locator('flt-semantics[role="button"]',{hasText:'Tour of this page'});
if(await q.count()>0) await q.last().click({force:true}); else {console.log(route,'no ? button');}
await p.waitForTimeout(3500);
let i=1, steps=[];
for(;i<=25;i++){
  const card=await p.locator('flt-semantics',{hasText:/ of \d+/}).count();
  const txt=await p.evaluate(()=>{const m=[...document.querySelectorAll('flt-semantics')].map(e=>e.textContent).find(t=>/\d+ of \d+/.test(t||''));return m?m.match(/\d+ of \d+/)[0]:'';});
  await p.screenshot({path:`${out}/${name}-${String(i).padStart(2,'0')}.png`});
  steps.push(txt);
  const done=p.locator('flt-semantics[role="button"]',{hasText:/^Done$/});
  if(await done.count()>0){await done.last().click({force:true});await p.waitForTimeout(2500);break;}
  let next=p.locator('flt-semantics[role="button"]',{hasText:/^Next$/});
  for(let w=0;w<20 && await next.count()===0;w++){await p.waitForTimeout(500);}
  if(await next.count()===0){console.log(route,'stuck at',i);break;}
  await next.last().click({force:true});await p.waitForTimeout(4000);
}
await p.screenshot({path:`${out}/${name}-end.png`});
console.log(route, steps.join(','));
await p.close();}
await b.close();})();
