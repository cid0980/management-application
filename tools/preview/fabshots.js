// open a route, tap the FAB (bottom right), screenshot, scroll, screenshot
const {chromium}=require('playwright');
(async()=>{const out=process.argv[2];const b=await chromium.launch();
for(const r of process.argv.slice(3)){
const p=await b.newPage({viewport:{width:412,height:892},deviceScaleFactor:2});
await p.goto('http://localhost:8812/#'+r);await p.waitForTimeout(5500);
await p.mouse.click(330,800);await p.waitForTimeout(2500);
const n=r.replace(/[\/]+/g,'_');
await p.screenshot({path:`${out}/form${n}-1.png`});
await p.mouse.move(206,500);for(let k=0;k<1500;k+=300){await p.mouse.wheel(0,300);await p.waitForTimeout(120);}
await p.waitForTimeout(1000);await p.screenshot({path:`${out}/form${n}-2.png`});await p.close();}
await b.close();})();
