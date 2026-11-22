const {chromium}=require('playwright');
// One symbol, drawn on a 108-unit canvas (Android adaptive icon grid; the
// visible safe zone is the middle 66).
const symbol=`
  <rect x="38" y="25" width="32" height="58" rx="7" fill="none" stroke="#fff" stroke-width="5"/>
  <rect x="48" y="31" width="12" height="3" rx="1.5" fill="#fff"/>
  <path d="M58 58 h16 a3 3 0 0 1 3 3 v9 a3 3 0 0 1 -3 3 h-16 l-7 -7.5 z" fill="#2DD4A7"/>
  <circle cx="57.5" cy="65.5" r="2" fill="#5A62D6"/>`;
const full=(s)=>`<svg xmlns="http://www.w3.org/2000/svg" width="${s}" height="${s}" viewBox="0 0 108 108"><rect width="108" height="108" fill="#5A62D6"/>${symbol}</svg>`;
const round=(s)=>`<svg xmlns="http://www.w3.org/2000/svg" width="${s}" height="${s}" viewBox="9 9 90 90"><rect x="9" y="9" width="90" height="90" rx="20" fill="#5A62D6"/>${symbol}</svg>`;
const fg=(s)=>`<svg xmlns="http://www.w3.org/2000/svg" width="${s}" height="${s}" viewBox="0 0 108 108">${symbol}</svg>`;
(async()=>{const b=await chromium.launch();const p=await b.newPage();
async function shot(svg,s,file,transparent){await p.setViewportSize({width:s,height:s});await p.setContent(`<html><body style="margin:0;background:transparent">${svg}</body></html>`);await p.screenshot({path:file,omitBackground:!!transparent,clip:{x:0,y:0,width:s,height:s}});}
const legacy={mdpi:48,hdpi:72,xhdpi:96,xxhdpi:144,xxxhdpi:192};
for(const [d,s] of Object.entries(legacy)){await shot(round(s),s,`ic_launcher-${d}.png`,true);await shot(fg(Math.round(s*2.25)),Math.round(s*2.25),`ic_launcher_foreground-${d}.png`,true);}
await shot(full(512),512,'play-store-icon-512.png',false);
await b.close();})();
